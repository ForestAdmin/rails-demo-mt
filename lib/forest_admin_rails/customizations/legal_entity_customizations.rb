module ForestAdminRails
  module Customizations
    module LegalEntityCustomizations
      ACTION = ForestAdminDatasourceCustomizer::Decorators::Action::BaseAction

      def self.apply(agent)
        agent.customize_collection("LegalEntity") do |collection|
          # Remove the polymorphic :entity relation and its FK columns.
          # FA cannot project entity_id/entity_type without trying to resolve
          # the polymorphic join, which crashes at query time.
          # entity_name/entity_email computed fields fetch entity data directly
          # via SQL on :id instead, so these columns are not needed in the schema.
          collection.remove_field("entity")
          collection.remove_field("entity_id")
          collection.remove_field("entity_type")
          add_fields(collection)
          add_segments(collection)
          add_actions(collection)
          add_search(collection)
        end
      end

      def self.add_fields(collection)
        # entity_name — Business.business_name or Individual full name
        # depends_on ["id"] only: FA cannot project entity_id/entity_type through
        # the polymorphic :entity relation, so we fetch them ourselves via SQL.
        collection.computed_field("entity_name", type: "String", depends_on: ["id"]) do |records|
          ids  = records.map { |r| r["id"].to_i }
          refs = LegalEntity.where(id: ids).pluck(:id, :entity_id, :entity_type)
                            .each_with_object({}) { |(id, eid, etype), h| h[id] = { id: eid, type: etype } }

          business_ids   = refs.values.select { |e| e[:type] == "Business"   }.map { |e| e[:id] }
          individual_ids = refs.values.select { |e| e[:type] == "Individual" }.map { |e| e[:id] }
          businesses     = Business.where(id: business_ids).index_by(&:id)
          individuals    = Individual.where(id: individual_ids).index_by(&:id)

          records.map do |r|
            entity = refs[r["id"].to_i]
            next nil unless entity
            case entity[:type]
            when "Business"   then businesses[entity[:id]]&.business_name
            when "Individual"
              ind = individuals[entity[:id]]
              ind ? "#{ind.first_name} #{ind.last_name}".strip : nil
            end
          end
        rescue => e
          Rails.logger.error("[entity_name] #{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
          records.map { nil }
        end

        # entity_email — primary_email from Business or Individual (same approach)
        collection.computed_field("entity_email", type: "String", depends_on: ["id"]) do |records|
          ids  = records.map { |r| r["id"].to_i }
          refs = LegalEntity.where(id: ids).pluck(:id, :entity_id, :entity_type)
                            .each_with_object({}) { |(id, eid, etype), h| h[id] = { id: eid, type: etype } }

          business_ids   = refs.values.select { |e| e[:type] == "Business"   }.map { |e| e[:id] }
          individual_ids = refs.values.select { |e| e[:type] == "Individual" }.map { |e| e[:id] }
          businesses     = Business.where(id: business_ids).index_by(&:id)
          individuals    = Individual.where(id: individual_ids).index_by(&:id)

          records.map do |r|
            entity = refs[r["id"].to_i]
            next nil unless entity
            case entity[:type]
            when "Business"   then businesses[entity[:id]]&.primary_email
            when "Individual" then individuals[entity[:id]]&.primary_email
            end
          end
        rescue => e
          Rails.logger.error("[entity_email] #{e.class}: #{e.message}\n#{e.backtrace.first(3).join("\n")}")
          records.map { nil }
        end

        # tier — C1 if not a child in any LegalEntityRelationship, C2 otherwise
        collection.computed_field("tier", type: "Enum", depends_on: ["id"],
                                          enum_values: ["C1", "C2"]) do |records|
          ids       = records.map { |r| r["id"].to_i }
          child_ids = LegalEntityRelationship.where(child_legal_entity_id: ids).pluck(:child_legal_entity_id).to_set
          records.map { |r| child_ids.include?(r["id"].to_i) ? "C2" : "C1" }
        rescue => e
          Rails.logger.error("[tier] #{e.class}: #{e.message}")
          records.map { "C1" }
        end

        # active_transfers_held_count — held transfers across all accounts
        collection.computed_field("active_transfers_held_count", type: "Number", depends_on: ["id"]) do |records|
          ids = records.map { |r| r["id"].to_i }.reject(&:zero?)
          next records.map { 0 } if ids.empty?

          counts = ActiveRecord::Base.connection.execute(
            "SELECT a.legal_entity_id, COUNT(t.id) AS cnt
             FROM transfers t
             JOIN accounts a ON t.account_id = a.id
             WHERE a.legal_entity_id IN (#{ids.join(",")})
             AND t.status = 'held'
             GROUP BY a.legal_entity_id"
          ).each_with_object({}) { |row, h| h[row["legal_entity_id"].to_i] = row["cnt"].to_i }
          records.map { |r| counts.fetch(r["id"].to_i, 0) }
        rescue => e
          Rails.logger.error("[active_transfers_held_count] #{e.class}: #{e.message}")
          records.map { 0 }
        end

        # kyb_status — latest Decision status (batch load)
        collection.computed_field("kyb_status", type: "Enum", depends_on: ["id"],
                                                enum_values: %w[passed needs_review failed running expired none]) do |records|
          ids    = records.map { |r| r["id"].to_i }
          latest = Decision.where(legal_entity_id: ids)
                           .order(created_at: :desc)
                           .group_by(&:legal_entity_id)
                           .transform_values { |decisions| decisions.first.status }
          records.map { |r| latest.fetch(r["id"].to_i, "none") }
        rescue => e
          Rails.logger.error("[kyb_status] #{e.class}: #{e.message}")
          records.map { "none" }
        end
      end

      def self.add_segments(collection)
        collection.add_segment("Onboarding") { { field: "status", operator: "Equal", value: "pending" } }
        collection.add_segment("High Risk")  { { field: "risk_rating", operator: "Equal", value: "high" } }
      end

      def self.add_search(collection)
        collection.replace_search do |search_string, _extended|
          {
            aggregator: "Or",
            conditions: [
              { field: "external_id",   operator: "IContains", value: search_string },
              { field: "entity_name",   operator: "IContains", value: search_string },
              { field: "entity_email",  operator: "IContains", value: search_string }
            ]
          }
        end
      end

      def self.add_actions(collection)
        # Send RFI — creates a PersonaInquiry (stub: Airtable; production: Persona API)
        #
        # Production equivalent — POST https://withpersona.com/api/v1/inquiries
        #   Headers:  Authorization: Bearer ENV["PERSONA_API_KEY"]
        #             Persona-Version: 2023-01-05
        #   Body: {
        #     data: {
        #       attributes: {
        #         inquiry_template_id: "itmpl_xxx",   
        #         reference_id:        entity["id"].to_s,
        #         fields: {
        #           "email-address" => context.form_values["Recipient email"],
        #           "name-first"    => <entity first_name if individual>
        #         }
        #       }
        #     }
        #   }
        #   Response: { data: { id: "inq_xxx", attributes: { status: "created",
        #                session_token: "st_xxx" } } }
        #   One-time link: https://withpersona.com/verify?inquiry-id=inq_xxx&session-token=st_xxx
        #
        # Sending an email via Persona (channel = "email"):
        #   POST https://withpersona.com/api/v1/inquiries/<inq_id>/resume
        #   Body: { data: { attributes: { send_email: true } } }
        collection.add_action("Send RFI", ACTION.new(
          scope: "Single",
          form: [
            { type: "Enum",    label: "Template type", is_required: true,
              enum_values: %w[source_of_funds ubo_documentation proof_of_address transaction_purpose] },
            { type: "Enum",    label: "Channel", is_required: true, default_value: "persona_link",
              enum_values: %w[persona_link email] },
            { type: "String",  label: "Recipient email", is_required: false },
            { type: "String",  label: "Notes", is_required: false }
          ]
        ) do |context, result_builder|
          entity      = context.get_record(["id"])
          inquiry_id  = "inq_#{SecureRandom.hex(8)}"
          link        = "https://withpersona.com/verify?inquiry-template-id=itmpl_demo&reference-id=#{inquiry_id}"

          result_builder.success("RFI sent", { type: "Text", message: "One-time-link: #{link}" })
        end)

        # Enable Payments — set status to active
        collection.add_action("Enable Payments", ACTION.new(
          scope: "Single",
          form: [{ type: "String", label: "Reasoning", is_required: true }]
        ) do |context, result_builder|
          entity = context.get_record(["id"])
          LegalEntity.find(entity["id"]).update!(status: "active")
          result_builder.success("Payments enabled")
        end)

        # Suspend Entity — approval configured in FA UI
        collection.add_action("Suspend Entity", ACTION.new(
          scope: "Single",
          form: [
            { type: "Enum",   label: "Reason", is_required: true,
              enum_values: %w[fraud_confirmed sanctions_hit compliance_directive customer_request] },
            { type: "String", label: "Reasoning", is_required: true }
          ]
        ) do |context, result_builder|
          entity = context.get_record(["id"])
          LegalEntity.find(entity["id"]).update!(status: "suspended")
          result_builder.success("Entity suspended")
        end)
      end


    end
  end
end
