require_relative "airtable_datasource"

module ForestAdminRails
  module Datasources
    # Wraps AirtableDatasource as a proper Forest Admin Datasource so the
    # Airtable table appears as a standalone collection in the FA sidebar.
    #
    # Inspired by the Node.js datasource-airtable package
    # (ForestAdmin/forestadmin-experimental).
    #
    # Usage in create_agent.rb:
    #   ds = AirtableForestDatasource.from_env(collection_name: "PersonaInquiry")
    #   @create_agent.add_datasource(ds) if ds
    class AirtableForestDatasource < ForestAdminDatasourceToolkit::Datasource
      def self.from_env(collection_name: "PersonaInquiry")
        return nil unless ENV["AIRTABLE_API_KEY"] && ENV["AIRTABLE_BASE_ID"] && ENV["AIRTABLE_TABLE_ID"]

        airtable = AirtableDatasource.from_env
        new(airtable, collection_name: collection_name)
      rescue => e
        Rails.logger.warn("[AirtableForestDatasource] Unavailable — #{e.message}")
        nil
      end

      def initialize(airtable, collection_name: "PersonaInquiry")
        super()
        add_collection(AirtableForestCollection.new(self, collection_name, airtable))
      end
    end

    # A read/create Forest Admin Collection backed by a single Airtable table.
    # Schema is auto-discovered from the Airtable Meta API at init time.
    class AirtableForestCollection < ForestAdminDatasourceToolkit::Collection
      def initialize(datasource, name, airtable)
        super(datasource, name)
        @airtable = airtable
        enable_count
        build_schema
      end

      # Returns records from Airtable, applying id / legal_entity_id filters when present.
      def list(_caller, filter, _projection)
        records = @airtable.list(filter_formula: extract_formula(filter))
        apply_id_filter(records, filter)
      end

      # FA calls this for count badges and the summary bar.
      def aggregate(_caller, filter, aggregation, _limit = nil)
        records = @airtable.list(filter_formula: extract_formula(filter))
        [{ value: records.count, group: {} }]
      end

      def create(_caller, data)
        @airtable.create(data)
      end

      def update(_caller, _filter, _data)
        raise ForestAdminDatasourceToolkit::Exceptions::ForestException,
              "Airtable collection is not updatable from Forest Admin"
      end

      def delete(_caller, _filter)
        raise ForestAdminDatasourceToolkit::Exceptions::ForestException,
              "Airtable collection is not deletable from Forest Admin"
      end

      def execute(_caller, _name, _data, _filter = nil)
        raise ForestAdminDatasourceToolkit::Exceptions::ForestException, "No actions defined"
      end

      def get_form(_caller, _name, _data = nil, _filter = nil, _metas = {})
        []
      end

      private

      # Translates a single-condition FA filter to an Airtable formula.
      # Supports: legal_entity_id = X (for workspace sourcing)
      # id filtering is handled in-memory by apply_id_filter (Airtable record IDs
      # live outside the fields namespace and can't be used in filter formulas).
      def extract_formula(filter)
        return nil unless filter&.condition_tree
        ct = filter.condition_tree
        return nil unless ct.respond_to?(:field) &&
                          ct.field == "legal_entity_id" &&
                          ct.operator == "Equal"
        "({legal_entity_id}='#{ct.value}')"
      end

      # Filters records by Airtable record ID in-memory (Equal / In).
      def apply_id_filter(records, filter)
        return records unless filter&.condition_tree
        ct = filter.condition_tree
        return records unless ct.respond_to?(:field) && ct.field == "id"
        case ct.operator
        when "Equal" then records.select { |r| r["id"] == ct.value }
        when "In"    then records.select { |r| Array(ct.value).include?(r["id"]) }
        else records
        end
      end

      # Build the FA schema from the Airtable Meta API response.
      # Mirrors the field-type mapping in the Node.js datasource-airtable package.
      def build_schema
        add_field("id", ForestAdminDatasourceToolkit::Schema::ColumnSchema.new(
          column_type:      "String",
          filter_operators: Set.new(["Equal", "In"]),
          is_primary_key:   true,
          is_read_only:     true,
          is_sortable:      false
        ))

        @airtable.schema.each do |name, meta|
          add_field(name, ForestAdminDatasourceToolkit::Schema::ColumnSchema.new(
            column_type:      meta[:column_type],
            enum_values:      meta[:enum_values] || [],
            filter_operators: Set.new,
            is_primary_key:   false,
            is_read_only:     meta[:read_only],
            is_sortable:      false
          ))
        end
      end
    end
  end
end
