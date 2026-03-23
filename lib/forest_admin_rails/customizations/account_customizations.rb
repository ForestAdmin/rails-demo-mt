module ForestAdminRails
  module Customizations
    module AccountCustomizations
      ACTION = ForestAdminDatasourceCustomizer::Decorators::Action::BaseAction

      def self.apply(agent)
        agent.customize_collection("Account") do |collection|
          add_fields(collection)
          add_segments(collection)
          add_actions(collection)
        end
      end

      def self.add_fields(collection)
        # available_balance — formatted available amount from AccountBalance (batch load)
        collection.computed_field("available_balance", type: "String", depends_on: ["id"]) do |records|
          ids      = records.map { |r| r["id"] }
          balances = AccountBalance.where(account_id: ids).index_by(&:account_id)
          records.map do |r|
            amount = balances[r["id"]]&.available_amount
            amount ? "$#{format("%.2f", amount / 100.0)}" : nil
          end
        end

        # posted_balance — formatted posted amount from AccountBalance (batch load)
        collection.computed_field("posted_balance", type: "String", depends_on: ["id"]) do |records|
          ids      = records.map { |r| r["id"] }
          balances = AccountBalance.where(account_id: ids).index_by(&:account_id)
          records.map do |r|
            amount = balances[r["id"]]&.posted_amount
            amount ? "$#{format("%.2f", amount / 100.0)}" : nil
          end
        end
      end

      def self.add_segments(collection)
        collection.add_segment("Active")    { { field: "status", operator: "Equal", value: "active" } }
        collection.add_segment("Suspended") { { field: "status", operator: "Equal", value: "suspended" } }
      end

      def self.add_actions(collection)
        # Freeze Account — approval configured in FA UI
        collection.add_action("Freeze Account", ACTION.new(
          scope: "Single",
          form: [
            { type: "Enum",   label: "Reason", is_required: true,
              enum_values: %w[fraud_suspected sanctions_hit compliance_directive customer_request] },
            { type: "String", label: "Notes", is_required: true }
          ]
        ) do |context, result_builder|
          record = context.get_record(["id", "status"])
          if record["status"] == "suspended"
            next result_builder.error("Account is already frozen.")
          end
          Account.find(record["id"]).update!(status: "suspended", suspended_at: Time.now)
          result_builder.success("Account frozen")
        end)

        # Unfreeze Account — no approval, only available when suspended
        collection.add_action("Unfreeze Account", ACTION.new(
          scope: "Single",
          form: [
            { type: "String", label: "Notes", is_required: true }
          ]
        ) do |context, result_builder|
          record = context.get_record(["id", "status"])
          unless record["status"] == "suspended"
            next result_builder.error("Account is not frozen.")
          end
          Account.find(record["id"]).update!(status: "active", active_at: Time.now, suspended_at: nil)
          result_builder.success("Account unfrozen")
        end)

        # Initiate Account Closure — approval configured in FA UI
        collection.add_action("Initiate Account Closure", ACTION.new(
          scope: "Single",
          form: [
            { type: "Enum",    label: "Reason", is_required: true,
              enum_values: %w[customer_request fraud_confirmed inactivity compliance_directive] },
            { type: "String",  label: "Notes", is_required: true },
            { type: "Boolean", label: "Notify customer", is_required: false }
          ]
        ) do |context, result_builder|
          record = context.get_record(["id", "status"])
          if %w[pending_closure closed].include?(record["status"])
            next result_builder.error("Account closure already initiated or account is closed.")
          end
          Account.find(record["id"]).update!(status: "pending_closure", pending_closure_at: Time.now)
          result_builder.success("Account closure initiated — pending approval")
        end)
      end
    end
  end
end
