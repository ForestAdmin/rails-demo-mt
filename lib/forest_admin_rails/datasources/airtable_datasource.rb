require "net/http"
require "json"

module ForestAdminRails
  module Datasources
    # Generic, reusable Airtable datasource.
    #
    # Discovers its schema automatically from the Airtable Meta API at first use,
    # so fields never need to be hard-coded.
    #
    # Usage:
    #   datasource = AirtableDatasource.new(api_key: "...", base_id: "...", table_id: "...")
    #   datasource = AirtableDatasource.from_env   # reads AIRTABLE_API_KEY/BASE_ID/TABLE_ID
    #
    #   datasource.schema         # => { "name" => { column_type:, read_only:, enum_values: }, ... }
    #   datasource.list           # => [{ "id" => "recXXX", "name" => "...", ... }, ...]
    #   datasource.list(filter_formula: "({status}='pending')")
    #   datasource.create("name" => "Acme", "status" => "pending")
    #
    class AirtableDatasource
      META_URL      = "https://api.airtable.com/v0/meta".freeze
      BASE_URL      = "https://api.airtable.com/v0".freeze
      PAGE_SIZE     = 100
      MAX_RETRIES   = 5
      INITIAL_DELAY = 1.0 # seconds

      # Field types that Airtable computes server-side and rejects on writes.
      READ_ONLY_TYPES = %w[
        formula rollup count autoNumber
        createdTime lastModifiedTime
        createdBy lastModifiedBy
        lookup button
      ].freeze

      # ── Factory ─────────────────────────────────────────────────────────────

      def self.from_env
        new(
          api_key:  ENV.fetch("AIRTABLE_API_KEY"),
          base_id:  ENV.fetch("AIRTABLE_BASE_ID"),
          table_id: ENV.fetch("AIRTABLE_TABLE_ID")
        )
      end

      # ── Initializer ──────────────────────────────────────────────────────────

      def initialize(api_key:, base_id:, table_id:)
        @api_key  = api_key
        @base_id  = base_id
        @table_id = table_id
        @schema   = nil # lazily populated from Meta API
      end

      # ── Public interface ─────────────────────────────────────────────────────

      # Returns the introspected schema, fetched once and cached per instance.
      # Shape: { "field_name" => { column_type:, read_only:, enum_values: }, ... }
      def schema
        @schema ||= fetch_schema
      end

      # Lists records, with optional Airtable formula filter.
      # Handles multi-page results transparently.
      def list(filter_formula: nil)
        fetch_all_pages(filter_formula)
      end

      # Creates a single record. Only writable fields are sent to Airtable.
      def create(attrs)
        writable = serialize_fields(attrs)
        body = { fields: writable }.to_json
        response = request_with_retry(:post, records_url, body: body)
        deserialize_record(response)
      end

      # ── Schema introspection ─────────────────────────────────────────────────

      private

      def fetch_schema
        url = "#{META_URL}/bases/#{@base_id}/tables"
        response = request_with_retry(:get, url)

        table = response["tables"]&.find { |t| t["id"] == @table_id || t["name"] == @table_id }
        raise "Airtable table '#{@table_id}' not found in base '#{@base_id}'" unless table

        table["fields"].each_with_object({}) do |field, schema|
          schema[field["name"]] = {
            airtable_type: field["type"],
            column_type:   to_column_type(field),
            read_only:     READ_ONLY_TYPES.include?(field["type"]),
            enum_values:   extract_enum_values(field)
          }
        end
      end

      # Maps Airtable field types to Forest Admin column types.
      # Based on the type-converter from forestadmin-experimental/datasource-airtable.
      def to_column_type(field)
        case field["type"]
        when "singleLineText", "email", "url", "phoneNumber",
             "richText", "multilineText",
             "singleSelect",
             "formula",          # formula result may vary; default to String
             "multipleLookupValues", "multipleSelects",
             "recordLink",
             "barcode"
          "String"
        when "number", "percent", "currency",
             "autoNumber", "count", "rating", "duration"
          "Number"
        when "checkbox"
          "Boolean"
        when "date"
          "Dateonly"
        when "dateTime", "createdTime", "lastModifiedTime"
          "Date"
        else
          "String"
        end
      end

      def extract_enum_values(field)
        return nil unless field["type"] == "singleSelect"
        field.dig("options", "choices")&.map { |c| c["name"] }
      end

      # ── Pagination ───────────────────────────────────────────────────────────

      def fetch_all_pages(filter_formula, offset: nil, accumulated: [])
        params = { "pageSize" => PAGE_SIZE }
        params["filterByFormula"] = filter_formula if filter_formula
        params["offset"]          = offset         if offset

        response = request_with_retry(:get, "#{records_url}?#{URI.encode_www_form(params)}")
        records  = (response["records"] || []).map { |r| deserialize_record(r) }
        accumulated.concat(records)

        next_offset = response["offset"]
        if next_offset
          fetch_all_pages(filter_formula, offset: next_offset, accumulated: accumulated)
        else
          accumulated
        end
      end

      # ── Serialisation ────────────────────────────────────────────────────────

      # Airtable record → plain Ruby hash with Forest Admin-friendly values.
      def deserialize_record(record)
        fields = record["fields"] || {}
        result = { "id" => record["id"] }

        schema.each do |name, meta|
          result[name] = deserialize_value(fields[name], meta)
        end

        result
      end

      def deserialize_value(value, meta)
        case meta[:column_type]
        when "Boolean"
          # Airtable omits checkbox fields when false
          value || false
        when "String"
          # Multi-select and lookup return arrays — join for Forest Admin
          value.is_a?(Array) ? value.join(", ") : value
        else
          value
        end
      end

      # Forest Admin attrs → Airtable fields, skipping read-only fields.
      def serialize_fields(attrs)
        attrs.each_with_object({}) do |(key, value), result|
          meta = schema[key]
          next unless meta           # unknown field → skip
          next if meta[:read_only]   # computed field → Airtable rejects writes
          result[key] = value
        end.compact
      end

      # ── HTTP ─────────────────────────────────────────────────────────────────

      def request_with_retry(method, url, body: nil, attempt: 0)
        response = perform_request(method, url, body)
        status   = response.code.to_i

        case status
        when 200, 201
          JSON.parse(response.body)
        when 429
          raise "Airtable rate limit exceeded after #{MAX_RETRIES} retries" if attempt >= MAX_RETRIES
          delay = retry_delay(response, attempt)
          Rails.logger.warn("[AirtableDatasource] 429 rate limited — retrying in #{delay.round(2)}s (attempt #{attempt + 1}/#{MAX_RETRIES})")
          sleep(delay)
          request_with_retry(method, url, body: body, attempt: attempt + 1)
        when 503, 504
          raise "Airtable unavailable after #{MAX_RETRIES} retries" if attempt >= MAX_RETRIES
          sleep(backoff_delay(attempt))
          request_with_retry(method, url, body: body, attempt: attempt + 1)
        when 401, 403
          raise "Airtable authentication error (#{status}) — check AIRTABLE_API_KEY"
        when 404
          raise "Airtable resource not found (404) — check AIRTABLE_BASE_ID and AIRTABLE_TABLE_ID"
        else
          raise "Airtable API error #{status}: #{response.body}"
        end
      end

      def perform_request(method, url, body = nil)
        uri  = URI(url)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true

        req = case method
              when :get  then Net::HTTP::Get.new(uri)
              when :post then Net::HTTP::Post.new(uri)
              end

        req["Authorization"] = "Bearer #{@api_key}"
        req["Content-Type"]  = "application/json" if body
        req.body = body if body

        http.request(req)
      end

      def retry_delay(response, attempt)
        retry_after = response["Retry-After"]&.to_f
        retry_after&.positive? ? retry_after : backoff_delay(attempt)
      end

      def backoff_delay(attempt)
        # Exponential backoff with ±25% jitter, capped at 30s
        base   = INITIAL_DELAY * (2**attempt)
        jitter = base * 0.25 * ((rand * 2) - 1)
        [base + jitter, 30.0].min
      end

      def records_url
        "#{BASE_URL}/#{@base_id}/#{@table_id}"
      end
    end
  end
end
