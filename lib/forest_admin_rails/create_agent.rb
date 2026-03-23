module ForestAdminRails
  class CreateAgent
    def self.setup!
      database_configuration = Rails.configuration.database_configuration
      datasource = ForestAdminDatasourceActiveRecord::Datasource.new(database_configuration[Rails.env], support_polymorphic_relations: true)

      @create_agent = ForestAdminAgent::Builder::AgentFactory.instance.add_datasource(datasource)
      customize
      @create_agent.build
    end

    def self.customize
      require_relative "datasources/airtable_datasource"
      require_relative "datasources/airtable_forest_datasource"
      require_relative "customizations/legal_entity_customizations"
      require_relative "customizations/transfer_customizations"
      require_relative "customizations/verification_customizations"
      require_relative "customizations/decision_customizations"
      require_relative "customizations/account_customizations"
      require_relative "customizations/persona_inquiry_customizations"
      require_relative "charts"

      airtable_ds = ForestAdminRails::Datasources::AirtableForestDatasource.from_env(collection_name: "PersonaInquiry")
      @create_agent.add_datasource(airtable_ds) if airtable_ds

      ForestAdminRails::Customizations::LegalEntityCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::TransferCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::VerificationCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::DecisionCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::AccountCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::PersonaInquiryCustomizations.apply(@create_agent) if airtable_ds
      ForestAdminRails::Charts.register(@create_agent)

      # ── Remove internal collections not relevant to operators ─────────────────
      # FailedSidekiqPush — internal job error log, never useful in the UI
      @create_agent.remove_collection("FailedSidekiqPush")

      # ── Remove sensitive / internal fields ────────────────────────────────────
      # Business.encrypted_kms_key — encryption key reference, should never surface in UI
      @create_agent.customize_collection("Business") do |collection|
        collection.remove_field("encrypted_kms_key")
      end
    end
  end
end
