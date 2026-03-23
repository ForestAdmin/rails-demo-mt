module ForestAdminRails
  module Customizations
    module DecisionCustomizations
      ACTION = ForestAdminDatasourceCustomizer::Decorators::Action::BaseAction

      def self.apply(agent)
        agent.customize_collection("Decision") do |collection|
          add_fields(collection)
          add_segments(collection)
          add_actions(collection)
        end
      end

      def self.add_fields(collection)
        # days_until_expiry — days remaining before this decision expires (negative = already expired)
        collection.computed_field("days_until_expiry", type: "Number", depends_on: ["expires_at"]) do |records|
          records.map do |r|
            expires_at = r["expires_at"]
            expires_at ? ((expires_at - Time.now) / 86400).round(1) : nil
          end
        end

        # expiry_status — traffic light for decision freshness
        collection.computed_field("expiry_status", type: "Enum", depends_on: ["expires_at"],
                                                   enum_values: %w[ok expiring_soon expired]) do |records|
          records.map do |r|
            expires_at = r["expires_at"]
            next nil unless expires_at
            days_left = (expires_at - Time.now) / 86400
            if days_left < 0
              "expired"
            elsif days_left < 30
              "expiring_soon"
            else
              "ok"
            end
          end
        end
      end

      def self.add_segments(collection)
        collection.add_segment("Needs Review") { { field: "status", operator: "Equal", value: "needs_review" } }

        collection.add_segment("Expiring Soon") do
          {
            aggregator: "And",
            conditions: [
              { field: "expires_at", operator: "Present" },
              { field: "expires_at", operator: "LessThan", value: 30.days.from_now.iso8601 }
            ]
          }
        end
      end

      def self.add_actions(collection)
        # Resolve Decision — marks a needs_review decision as passed
        collection.add_action("Resolve Decision", ACTION.new(
          scope: "Single",
          form: [{ type: "String", label: "Notes", is_required: false }]
        ) do |context, result_builder|
          record = context.get_record(["id", "status"])
          unless record["status"] == "needs_review"
            next result_builder.error("Only 'needs_review' decisions can be resolved.")
          end
          Decision.find(record["id"]).update!(
            status:      "passed",
            resolved_by: context.caller.email
          )
          result_builder.success("Decision resolved")
        end)
      end
    end
  end
end
