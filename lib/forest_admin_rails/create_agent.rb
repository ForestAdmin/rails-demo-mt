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
      require_relative "charts"

      airtable_ds = ForestAdminRails::Datasources::AirtableForestDatasource.from_env(collection_name: "PersonaInquiry")
      @create_agent.add_datasource(airtable_ds) if airtable_ds

      ForestAdminRails::Customizations::LegalEntityCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::TransferCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::VerificationCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::DecisionCustomizations.apply(@create_agent)
      ForestAdminRails::Customizations::AccountCustomizations.apply(@create_agent)
      ForestAdminRails::Charts.register(@create_agent)
    end
  end
end
