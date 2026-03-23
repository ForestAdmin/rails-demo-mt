module ForestAdminRails
  module Customizations
    module VerificationCustomizations
      def self.apply(agent)
        agent.customize_collection("Verification__Sardine") do |collection|
          add_segments(collection)
        end
      end

      def self.add_segments(collection)
        collection.add_segment("Active Alerts") do |_context|
          { field: "status", operator: "Equal", value: "held" }
        end
      end
    end
  end
end
