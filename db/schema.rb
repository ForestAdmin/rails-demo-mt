# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_03_20_100000) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "public.account_balances", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "available_amount", default: 0
    t.datetime "created_at", null: false
    t.datetime "effective_at"
    t.integer "lock_version", default: 0
    t.bigint "pending_amount", default: 0
    t.bigint "posted_amount", default: 0
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_balances_on_account_id"
  end

  create_table "public.account_capabilities", force: :cascade do |t|
    t.bigint "account_id"
    t.bigint "bank_capability_id"
    t.uuid "cash_ledger_account_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.uuid "originating_account_id"
    t.bigint "program_limit_id"
    t.uuid "public_id"
    t.bigint "settlement_account_id"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_account_capabilities_on_account_id"
    t.index ["bank_capability_id"], name: "index_account_capabilities_on_bank_capability_id"
    t.index ["discarded_at"], name: "index_account_capabilities_on_discarded_at"
    t.index ["program_limit_id"], name: "index_account_capabilities_on_program_limit_id"
    t.index ["public_id"], name: "index_account_capabilities_on_public_id", unique: true
    t.index ["settlement_account_id"], name: "index_account_capabilities_on_settlement_account_id"
  end

  create_table "public.accounts", force: :cascade do |t|
    t.datetime "active_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.datetime "discarded_at"
    t.string "external_id"
    t.uuid "ledger_account_id"
    t.bigint "legal_entity_id"
    t.bigint "party_address_id"
    t.string "party_name"
    t.uuid "payable_ledger_account_id"
    t.datetime "pending_activation_at"
    t.datetime "pending_closure_at"
    t.uuid "public_id"
    t.uuid "receivable_ledger_account_id"
    t.string "status"
    t.datetime "suspended_at"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_accounts_on_discarded_at"
    t.index ["external_id"], name: "index_accounts_on_external_id"
    t.index ["legal_entity_id"], name: "index_accounts_on_legal_entity_id"
    t.index ["party_address_id"], name: "index_accounts_on_party_address_id"
    t.index ["public_id"], name: "index_accounts_on_public_id", unique: true
    t.index ["status"], name: "index_accounts_on_status"
  end

  create_table "public.ach_nocs", force: :cascade do |t|
    t.string "code"
    t.string "corrected_account_number"
    t.string "corrected_company_id"
    t.string "corrected_company_name"
    t.string "corrected_individual_identification_number"
    t.string "corrected_routing_number"
    t.string "corrected_transaction_code"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.uuid "public_id"
    t.string "settlement_id"
    t.bigint "transfer_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_ach_nocs_on_discarded_at"
    t.index ["public_id"], name: "index_ach_nocs_on_public_id", unique: true
    t.index ["transfer_id"], name: "index_ach_nocs_on_transfer_id"
  end

  create_table "public.addresses", force: :cascade do |t|
    t.string "address_type"
    t.string "country_code"
    t.datetime "created_at", null: false
    t.string "line1"
    t.string "line2"
    t.string "line3"
    t.string "locality"
    t.string "postal_code"
    t.string "region"
    t.datetime "updated_at", null: false
  end

  create_table "public.bank_capabilities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "direction"
    t.datetime "discarded_at"
    t.string "entity"
    t.bigint "limit"
    t.uuid "limit_contra_ledger_account_id"
    t.uuid "limit_ledger_account_id"
    t.string "payment_type"
    t.bigint "single_transfer_limit"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_bank_capabilities_on_discarded_at"
  end

  create_table "public.bank_legal_entities", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "entity"
    t.bigint "legal_entity_id"
    t.string "settlement_connection_legal_entity_id"
    t.string "settlement_legal_entity_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_bank_legal_entities_on_discarded_at"
    t.index ["legal_entity_id"], name: "index_bank_legal_entities_on_legal_entity_id"
  end

  create_table "public.books", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "originating_transfer_id"
    t.uuid "public_id"
    t.bigint "receiving_transfer_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_books_on_discarded_at"
    t.index ["originating_transfer_id"], name: "index_books_on_originating_transfer_id"
    t.index ["public_id"], name: "index_books_on_public_id", unique: true
    t.index ["receiving_transfer_id"], name: "index_books_on_receiving_transfer_id"
  end

  create_table "public.businesses", force: :cascade do |t|
    t.string "business_name"
    t.string "country_of_incorporation"
    t.datetime "created_at", null: false
    t.date "date_formed"
    t.string "description"
    t.string "doing_business_as_names", default: [], array: true
    t.string "encrypted_kms_key"
    t.bigint "expected_activity_volume"
    t.string "industry"
    t.string "intended_use"
    t.string "legal_structure"
    t.string "listed_exchange"
    t.string "naics_code"
    t.string "operating_jurisdictions", default: [], array: true
    t.bigint "physical_address_id"
    t.bigint "primary_address_id"
    t.string "primary_email"
    t.string "primary_phone"
    t.string "primary_social_media_sites", default: [], array: true
    t.uuid "public_id"
    t.string "regulator_jurisdiction"
    t.string "regulator_name"
    t.string "regulator_register_number"
    t.string "source_of_funds"
    t.string "ticker_symbol"
    t.datetime "updated_at", null: false
    t.string "wealth_source"
    t.string "website"
    t.index ["physical_address_id"], name: "index_businesses_on_physical_address_id"
    t.index ["primary_address_id"], name: "index_businesses_on_primary_address_id"
    t.index ["public_id"], name: "index_businesses_on_public_id", unique: true
  end

  create_table "public.decisions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "details"
    t.datetime "discarded_at"
    t.datetime "expires_at"
    t.bigint "legal_entity_id"
    t.string "resolved_by"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "vendor_id"
    t.index ["discarded_at"], name: "index_decisions_on_discarded_at"
    t.index ["legal_entity_id"], name: "index_decisions_on_legal_entity_id"
  end

  create_table "public.documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "document_type"
    t.bigint "documentable_id"
    t.string "documentable_type"
    t.uuid "public_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_documents_on_discarded_at"
    t.index ["documentable_type", "documentable_id"], name: "index_documents_on_documentable_type_and_documentable_id"
    t.index ["public_id"], name: "index_documents_on_public_id", unique: true
  end

  create_table "public.evaluations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "decision_id"
    t.jsonb "details"
    t.datetime "discarded_at"
    t.datetime "expires_at"
    t.bigint "legal_entity_id"
    t.string "resolved_by"
    t.string "status"
    t.datetime "updated_at", null: false
    t.string "vendor_id"
    t.index ["decision_id"], name: "index_evaluations_on_decision_id"
    t.index ["discarded_at"], name: "index_evaluations_on_discarded_at"
    t.index ["legal_entity_id"], name: "index_evaluations_on_legal_entity_id"
  end

  create_table "public.failed_sidekiq_pushes", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "error_message"
    t.jsonb "payloads"
    t.datetime "updated_at", null: false
  end

  create_table "public.identifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "encrypted_kms_key"
    t.string "id_number_ciphertext"
    t.string "id_type"
    t.bigint "identifiable_id"
    t.string "identifiable_type"
    t.string "issuing_country"
    t.string "issuing_region"
    t.uuid "public_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_identifications_on_discarded_at"
    t.index ["identifiable_type", "identifiable_id"], name: "index_identifications_on_identifiable_type_and_identifiable_id"
    t.index ["public_id"], name: "index_identifications_on_public_id", unique: true
  end

  create_table "public.individuals", force: :cascade do |t|
    t.bigint "annual_income"
    t.string "citizenship_country_code"
    t.datetime "created_at", null: false
    t.date "date_of_birth"
    t.string "description"
    t.string "employment_status"
    t.string "encrypted_kms_key"
    t.bigint "expected_activity_volume"
    t.string "first_name"
    t.string "income_source"
    t.string "industry"
    t.string "intended_use"
    t.string "last_name"
    t.string "middle_name"
    t.string "occupation"
    t.string "preferred_name"
    t.string "prefix"
    t.bigint "primary_address_id"
    t.string "primary_email"
    t.string "primary_phone"
    t.uuid "public_id"
    t.string "suffix"
    t.datetime "updated_at", null: false
    t.string "wealth_source"
    t.index ["primary_address_id"], name: "index_individuals_on_primary_address_id"
    t.index ["public_id"], name: "index_individuals_on_public_id", unique: true
  end

  create_table "public.legal_entities", force: :cascade do |t|
    t.datetime "active_at"
    t.datetime "closed_at"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "entity_id"
    t.string "entity_type"
    t.string "external_id"
    t.datetime "pending_at"
    t.bigint "program_id"
    t.uuid "public_id"
    t.string "risk_rating"
    t.string "role"
    t.string "status"
    t.datetime "suspended_at"
    t.datetime "updated_at", null: false
    t.string "vendor_id"
    t.index ["discarded_at"], name: "index_legal_entities_on_discarded_at"
    t.index ["entity_type", "entity_id"], name: "index_legal_entities_on_entity_type_and_entity_id"
    t.index ["external_id"], name: "index_legal_entities_on_external_id"
    t.index ["program_id"], name: "index_legal_entities_on_program_id"
    t.index ["public_id"], name: "index_legal_entities_on_public_id", unique: true
    t.index ["status"], name: "index_legal_entities_on_status"
  end

  create_table "public.legal_entity_relationships", force: :cascade do |t|
    t.bigint "child_legal_entity_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "external_id"
    t.integer "ownership_percentage"
    t.bigint "parent_legal_entity_id"
    t.uuid "public_id"
    t.string "relationship_types", default: [], array: true
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["child_legal_entity_id"], name: "index_legal_entity_relationships_on_child_legal_entity_id"
    t.index ["discarded_at"], name: "index_legal_entity_relationships_on_discarded_at"
    t.index ["parent_legal_entity_id"], name: "index_legal_entity_relationships_on_parent_legal_entity_id"
    t.index ["public_id"], name: "index_legal_entity_relationships_on_public_id", unique: true
  end

  create_table "public.program_entitlements", force: :cascade do |t|
    t.string "allowed_roles", default: [], array: true
    t.bigint "bank_capability_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.bigint "program_limit_id"
    t.uuid "public_id"
    t.datetime "updated_at", null: false
    t.index ["bank_capability_id"], name: "index_program_entitlements_on_bank_capability_id"
    t.index ["discarded_at"], name: "index_program_entitlements_on_discarded_at"
    t.index ["program_limit_id"], name: "index_program_entitlements_on_program_limit_id"
    t.index ["public_id"], name: "index_program_entitlements_on_public_id", unique: true
  end

  create_table "public.program_limits", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency"
    t.string "direction"
    t.datetime "discarded_at"
    t.bigint "limit"
    t.string "limit_ledger_account_id"
    t.datetime "limit_reset_at"
    t.string "payment_type"
    t.bigint "program_id"
    t.uuid "public_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_program_limits_on_discarded_at"
    t.index ["program_id"], name: "index_program_limits_on_program_id"
    t.index ["public_id"], name: "index_program_limits_on_public_id", unique: true
  end

  create_table "public.programs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "external_id"
    t.string "name"
    t.boolean "passthrough_compliance_enabled", default: false
    t.uuid "public_id"
    t.datetime "updated_at", null: false
    t.string "webhook_url"
    t.index ["discarded_at"], name: "index_programs_on_discarded_at"
    t.index ["external_id"], name: "index_programs_on_external_id"
    t.index ["public_id"], name: "index_programs_on_public_id", unique: true
  end

  create_table "public.returns", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.date "date_of_death"
    t.datetime "discarded_at"
    t.bigint "original_transfer_id"
    t.uuid "public_id"
    t.string "reason"
    t.bigint "return_transfer_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_returns_on_discarded_at"
    t.index ["original_transfer_id"], name: "index_returns_on_original_transfer_id"
    t.index ["public_id"], name: "index_returns_on_public_id", unique: true
    t.index ["return_transfer_id"], name: "index_returns_on_return_transfer_id"
  end

  create_table "public.settlement_accounts", force: :cascade do |t|
    t.bigint "account_id"
    t.uuid "cash_ledger_account_id"
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.string "entity"
    t.uuid "settlement_internal_account_id"
    t.string "status"
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_settlement_accounts_on_account_id"
    t.index ["discarded_at"], name: "index_settlement_accounts_on_discarded_at"
  end

  create_table "public.transfer_references", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.uuid "public_id"
    t.string "reference_type"
    t.string "reference_value"
    t.string "settlement_referenceable_id"
    t.bigint "transfer_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_transfer_references_on_discarded_at"
    t.index ["public_id"], name: "index_transfer_references_on_public_id", unique: true
    t.index ["transfer_id"], name: "index_transfer_references_on_transfer_id"
  end

  create_table "public.transfer_seasonings", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "discarded_at"
    t.datetime "end_at"
    t.string "status"
    t.bigint "transfer_id"
    t.datetime "updated_at", null: false
    t.index ["discarded_at"], name: "index_transfer_seasonings_on_discarded_at"
    t.index ["transfer_id"], name: "index_transfer_seasonings_on_transfer_id"
  end

  create_table "public.transfers", force: :cascade do |t|
    t.bigint "account_capability_id"
    t.bigint "account_id"
    t.string "account_role"
    t.bigint "amount"
    t.datetime "approved_at"
    t.datetime "cancelled_at"
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.string "currency"
    t.jsonb "data", default: {}
    t.string "direction"
    t.datetime "discarded_at"
    t.string "external_id"
    t.datetime "failed_at"
    t.string "failure_reason"
    t.datetime "held_at"
    t.uuid "ledger_transaction_id"
    t.integer "lock_version", default: 0
    t.string "payment_type"
    t.datetime "pending_at"
    t.datetime "processing_at"
    t.uuid "public_id"
    t.datetime "returned_at"
    t.datetime "reversed_at"
    t.datetime "sent_at"
    t.datetime "settlement_completed_at"
    t.string "settlement_id"
    t.string "status"
    t.string "transfer_type"
    t.datetime "updated_at", null: false
    t.index ["account_capability_id"], name: "index_transfers_on_account_capability_id"
    t.index ["account_id"], name: "index_transfers_on_account_id"
    t.index ["discarded_at"], name: "index_transfers_on_discarded_at"
    t.index ["external_id"], name: "index_transfers_on_external_id"
    t.index ["public_id"], name: "index_transfers_on_public_id", unique: true
    t.index ["status"], name: "index_transfers_on_status"
  end

  create_table "public.turbogrid_grid_states", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data"
    t.bigint "search_scope_id"
    t.datetime "updated_at", null: false
    t.index ["search_scope_id"], name: "index_turbogrid_grid_states_on_search_scope_id"
  end

  create_table "public.turbogrid_search_scopes", force: :cascade do |t|
    t.jsonb "columns"
    t.datetime "created_at", null: false
    t.jsonb "filter"
    t.string "namespace"
    t.string "resource"
    t.datetime "updated_at", null: false
  end

  create_table "public.verifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "data", default: {}
    t.datetime "discarded_at"
    t.string "rejection_reason"
    t.string "status"
    t.bigint "transfer_id"
    t.string "type"
    t.datetime "updated_at", null: false
    t.string "vendor_id"
    t.index ["discarded_at"], name: "index_verifications_on_discarded_at"
    t.index ["status"], name: "index_verifications_on_status"
    t.index ["transfer_id"], name: "index_verifications_on_transfer_id"
    t.index ["type"], name: "index_verifications_on_type"
  end

  add_foreign_key "public.account_balances", "public.accounts"
  add_foreign_key "public.account_capabilities", "public.accounts"
  add_foreign_key "public.account_capabilities", "public.bank_capabilities"
  add_foreign_key "public.account_capabilities", "public.program_limits"
  add_foreign_key "public.account_capabilities", "public.settlement_accounts"
  add_foreign_key "public.accounts", "public.addresses", column: "party_address_id"
  add_foreign_key "public.accounts", "public.legal_entities"
  add_foreign_key "public.ach_nocs", "public.transfers"
  add_foreign_key "public.bank_legal_entities", "public.legal_entities"
  add_foreign_key "public.books", "public.transfers", column: "originating_transfer_id"
  add_foreign_key "public.books", "public.transfers", column: "receiving_transfer_id"
  add_foreign_key "public.businesses", "public.addresses", column: "physical_address_id"
  add_foreign_key "public.businesses", "public.addresses", column: "primary_address_id"
  add_foreign_key "public.decisions", "public.legal_entities"
  add_foreign_key "public.evaluations", "public.decisions"
  add_foreign_key "public.evaluations", "public.legal_entities"
  add_foreign_key "public.individuals", "public.addresses", column: "primary_address_id"
  add_foreign_key "public.legal_entities", "public.programs"
  add_foreign_key "public.legal_entity_relationships", "public.legal_entities", column: "child_legal_entity_id"
  add_foreign_key "public.legal_entity_relationships", "public.legal_entities", column: "parent_legal_entity_id"
  add_foreign_key "public.program_entitlements", "public.bank_capabilities"
  add_foreign_key "public.program_entitlements", "public.program_limits"
  add_foreign_key "public.program_limits", "public.programs"
  add_foreign_key "public.returns", "public.transfers", column: "original_transfer_id"
  add_foreign_key "public.returns", "public.transfers", column: "return_transfer_id"
  add_foreign_key "public.settlement_accounts", "public.accounts"
  add_foreign_key "public.transfer_references", "public.transfers"
  add_foreign_key "public.transfer_seasonings", "public.transfers"
  add_foreign_key "public.transfers", "public.account_capabilities"
  add_foreign_key "public.transfers", "public.accounts"
  add_foreign_key "public.turbogrid_grid_states", "public.turbogrid_search_scopes", column: "search_scope_id"
  add_foreign_key "public.verifications", "public.transfers"

end
