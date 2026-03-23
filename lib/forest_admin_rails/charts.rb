module ForestAdminRails
  module Charts
    def self.register(agent)
      # Held payments count — primary operational KPI
      agent.add_chart("held_payments_count") do |_context, result_builder|
        result_builder.value(Transfer.where(status: "held").count)
      end

      # SLA breached count — transfers held for more than 6 hours
      agent.add_chart("sla_breached_count") do |_context, result_builder|
        count = Transfer.where(status: "held").where("held_at < ?", 6.hours.ago).count
        result_builder.value(count)
      end

      # Onboarding queue — entities pending activation
      agent.add_chart("onboarding_queue") do |_context, result_builder|
        result_builder.value(LegalEntity.where(status: "pending").count)
      end

      # High risk entities count
      agent.add_chart("high_risk_entities") do |_context, result_builder|
        result_builder.value(LegalEntity.where(risk_rating: "high").count)
      end

      # Transfer volume by status — distribution chart
      agent.add_chart("transfers_by_status") do |_context, result_builder|
        data = Transfer.group(:status).count.map do |status, count|
          { key: status.capitalize, value: count }
        end
        result_builder.distribution(data)
      end
    end
  end
end
