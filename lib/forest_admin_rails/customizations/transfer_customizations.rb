module ForestAdminRails
  module Customizations
    module TransferCustomizations
      ACTION = ForestAdminDatasourceCustomizer::Decorators::Action::BaseAction

      def self.apply(agent)
        agent.customize_collection("Transfer") do |collection|
          add_fields(collection)
          add_segments(collection)
          add_actions(collection)
        end
      end

      def self.add_fields(collection)
        # days_held — days since the transfer was put on hold
        collection.computed_field("days_held", type: "Number", depends_on: ["held_at"]) do |records|
          records.map do |r|
            held_at = r["held_at"]
            held_at = Time.parse(held_at) if held_at.is_a?(String)
            held_at ? ((Time.now - held_at) / 86400).round(1) : nil
          end
        rescue => e
          Rails.logger.error("[days_held] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # sla_status — traffic light (ok < 3h, warning < 6h, breached >= 6h)
        collection.computed_field("sla_status", type: "Enum", depends_on: ["held_at"],
                                               enum_values: %w[ok warning breached]) do |records|
          records.map do |r|
            held_at = r["held_at"]
            held_at = Time.parse(held_at) if held_at.is_a?(String)
            next nil unless held_at
            hours = (Time.now - held_at) / 3600
            hours < 3 ? "ok" : hours < 6 ? "warning" : "breached"
          end
        rescue => e
          Rails.logger.error("[sla_status] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # amount_display — cents to formatted dollar string
        collection.computed_field("amount_display", type: "String", depends_on: ["amount"]) do |records|
          records.map do |r|
            amount = r["amount"]&.to_i
            amount&.positive? || amount == 0 ? "$#{format("%.2f", amount / 100.0)}" : nil
          end
        rescue => e
          Rails.logger.error("[amount_display] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # escalated — whether this transfer has been manually escalated to Compliance
        collection.computed_field("escalated", type: "Boolean", depends_on: ["data"]) do |records|
          records.map do |r|
            data = r["data"]
            data = JSON.parse(data) if data.is_a?(String)
            data&.key?("escalated_at") || false
          end
        rescue => e
          Rails.logger.error("[escalated] #{e.class}: #{e.message}")
          records.map { false }
        end

        # escalation_priority — urgent / normal (from data jsonb)
        collection.computed_field("escalation_priority", type: "String", depends_on: ["data"]) do |records|
          records.map do |r|
            data = r["data"]
            data = JSON.parse(data) if data.is_a?(String)
            data&.dig("escalation_priority")
          end
        rescue => e
          Rails.logger.error("[escalation_priority] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # sardine_risk_score — risk score from Verification::Sardine JSON (batch load)
        collection.computed_field("sardine_risk_score", type: "Number", depends_on: ["id"]) do |records|
          ids      = records.map { |r| r["id"].to_i }
          sardines = Verification.where(transfer_id: ids, type: "Verification::Sardine")
                                 .index_by(&:transfer_id)
          records.map { |r| sardines[r["id"].to_i]&.data&.dig("risk_score") }
        rescue => e
          Rails.logger.error("[sardine_risk_score] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # sardine_alert_reason — alert reason from Verification::Sardine JSON (batch load)
        collection.computed_field("sardine_alert_reason", type: "String", depends_on: ["id"]) do |records|
          ids      = records.map { |r| r["id"].to_i }
          sardines = Verification.where(transfer_id: ids, type: "Verification::Sardine")
                                 .index_by(&:transfer_id)
          records.map { |r| sardines[r["id"].to_i]&.data&.dig("reason") }
        rescue => e
          Rails.logger.error("[sardine_alert_reason] #{e.class}: #{e.message}")
          records.map { nil }
        end

        # owner_name — name of the LegalEntity that owns the account
        # Transfer → account_id → Account → legal_entity_id → LegalEntity → entity (polymorphic, batched)
        collection.computed_field("owner_name", type: "String", depends_on: ["account_id"]) do |records|
          account_ids   = records.map { |r| r["account_id"].to_i }.compact.uniq
          le_by_account = Account.where(id: account_ids)
                                 .joins(:legal_entity)
                                 .pluck("accounts.id", "legal_entities.entity_id", "legal_entities.entity_type")
                                 .each_with_object({}) { |(aid, eid, etype), h| h[aid] = { id: eid, type: etype } }

          business_ids   = le_by_account.values.select { |e| e[:type] == "Business"   }.map { |e| e[:id] }
          individual_ids = le_by_account.values.select { |e| e[:type] == "Individual" }.map { |e| e[:id] }
          businesses     = Business.where(id: business_ids).index_by(&:id)
          individuals    = Individual.where(id: individual_ids).index_by(&:id)

          records.map do |r|
            entity_ref = le_by_account[r["account_id"].to_i]
            next nil unless entity_ref
            case entity_ref[:type]
            when "Business"   then businesses[entity_ref[:id]]&.business_name
            when "Individual"
              ind = individuals[entity_ref[:id]]
              ind ? "#{ind.first_name} #{ind.last_name}".strip : nil
            end
          end
        rescue => e
          Rails.logger.error("[owner_name] #{e.class}: #{e.message}")
          records.map { nil }
        end
      end

      def self.add_segments(collection)
        collection.add_segment("Held Payments") { { field: "status", operator: "Equal", value: "held" } }
      end

      def self.add_actions(collection)
        # Release Payment — single transfer release
        collection.add_action("Release Payment", ACTION.new(
          scope: "Single",
          form: [{ type: "String", label: "Reasoning", is_required: true }]
        ) do |context, result_builder|
          transfer = context.get_record(["id"])
          response = FlowApiClient.patch("/transfers/#{transfer["id"]}/release")
          response[:success] ? result_builder.success("Payment released") : result_builder.error("Flow API error: #{response[:error]}")
        end)

        # Release Held Payments — bulk release of selected held transfers
        collection.add_action("Release Held Payments", ACTION.new(
          scope: "Bulk",
          form: [{ type: "String", label: "Reasoning", is_required: true }]
        ) do |context, result_builder|
          records = context.get_records(["id", "status"])
          held    = records.select { |r| r["status"] == "held" }
          held.each { |t| FlowApiClient.patch("/transfers/#{t["id"]}/release") }
          result_builder.success("#{held.count} payment(s) released")
        end)

        # Escalate to Compliance — manual escalation outside the FA Workflow
        collection.add_action("Escalate to Compliance", ACTION.new(
          scope: "Single",
          form: [
            { type: "String", label: "Reasoning", is_required: true },
            { type: "Enum",   label: "Priority", is_required: true, default_value: "normal",
              enum_values: %w[normal urgent] }
          ]
        ) do |context, result_builder|
          transfer = context.get_record(["id", "status"])
          if transfer["status"] == "cancelled"
            next result_builder.error("Cannot escalate a cancelled transfer.")
          end
          t = Transfer.find(transfer["id"])
          t.update!(data: t.data.merge(
            "escalated_at"       => Time.now.iso8601,
            "escalated_by"       => context.caller.email,
            "escalation_priority" => context.form_values["Priority"],
            "escalation_reasoning" => context.form_values["Reasoning"]
          ))
          result_builder.success("Escalated to Compliance")
        end)

        # Sanctions Rescan — bulk retrigger Sardine screening on selected transfers
        #
        # Production equivalent — POST https://api.sardine.ai/v1/transfers/:id/rescan
        #   Headers: Authorization: Bearer ENV["SARDINE_API_KEY"]
        #   Body: { reason: "manual_rescan", notes: context.form_values["Notes"] }
        #   Response: { status: "submitted", transfer_id: "...", queued_at: "..." }
        collection.add_action("Sanctions Rescan", ACTION.new(
          scope: "Bulk",
          form: [{ type: "String", label: "Notes", is_required: false }]
        ) do |context, result_builder|
          records   = context.get_records(["id", "status"])
          eligible  = records.reject { |r| r["status"] == "cancelled" }
          eligible.each { |t| FlowApiClient.patch("/transfers/#{t["id"]}/rescan") }
          result_builder.success("#{eligible.count} transfer(s) submitted for sanctions rescan")
        end)

        # Block Payment — approval configured in FA UI
        collection.add_action("Block Payment", ACTION.new(
          scope: "Single",
          form: [
            { type: "Enum",    label: "Reason", is_required: true,
              enum_values: %w[fraud sanctions compliance_directive suspicious_activity] },
            { type: "String",  label: "Reasoning", is_required: true },
            { type: "Boolean", label: "Notify customer", is_required: false }
          ]
        ) do |context, result_builder|
          transfer = context.get_record(["id"])
          response = FlowApiClient.patch("/transfers/#{transfer["id"]}/cancel")
          response[:success] ? result_builder.success("Payment blocked") : result_builder.error("Flow API error: #{response[:error]}")
        end)
      end
    end
  end
end
