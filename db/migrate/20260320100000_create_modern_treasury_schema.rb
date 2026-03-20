class CreateModernTreasurySchema < ActiveRecord::Migration[8.1]
  def change
    # 1. addresses
    create_table :addresses do |t|
      t.string :address_type
      t.string :country_code
      t.string :line1
      t.string :line2
      t.string :line3
      t.string :locality
      t.string :postal_code
      t.string :region
      t.timestamps
    end

    # 2. programs
    create_table :programs do |t|
      t.string  :name
      t.string  :external_id
      t.uuid    :public_id
      t.string  :webhook_url
      t.boolean :passthrough_compliance_enabled, default: false
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :programs, :public_id, unique: true
    add_index :programs, :external_id
    add_index :programs, :discarded_at

    # 3. bank_capabilities
    create_table :bank_capabilities do |t|
      t.string  :currency
      t.string  :direction
      t.string  :entity
      t.string  :payment_type
      t.bigint  :limit
      t.bigint  :single_transfer_limit
      t.uuid    :limit_ledger_account_id
      t.uuid    :limit_contra_ledger_account_id
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :bank_capabilities, :discarded_at

    # 4. failed_sidekiq_pushes
    create_table :failed_sidekiq_pushes do |t|
      t.string :error_message
      t.jsonb  :payloads
      t.timestamps
    end

    # 5. turbogrid_search_scopes
    create_table :turbogrid_search_scopes do |t|
      t.string :namespace
      t.string :resource
      t.jsonb  :columns
      t.jsonb  :filter
      t.timestamps
    end

    # 6. turbogrid_grid_states
    create_table :turbogrid_grid_states do |t|
      t.references :search_scope, foreign_key: { to_table: :turbogrid_search_scopes }
      t.jsonb :data
      t.timestamps
    end

    # 7. individuals
    create_table :individuals do |t|
      t.string   :first_name
      t.string   :last_name
      t.string   :middle_name
      t.string   :preferred_name
      t.string   :prefix
      t.string   :suffix
      t.date     :date_of_birth
      t.string   :citizenship_country_code
      t.string   :primary_email
      t.string   :primary_phone
      t.string   :description
      t.string   :employment_status
      t.string   :occupation
      t.string   :industry
      t.string   :intended_use
      t.string   :income_source
      t.bigint   :annual_income
      t.bigint   :expected_activity_volume
      t.string   :wealth_source
      t.string   :encrypted_kms_key
      t.uuid     :public_id
      t.references :primary_address, foreign_key: { to_table: :addresses }, null: true
      t.timestamps
    end
    add_index :individuals, :public_id, unique: true

    # 8. businesses
    create_table :businesses do |t|
      t.string   :business_name
      t.string   :country_of_incorporation
      t.date     :date_formed
      t.string   :description
      t.string   :doing_business_as_names, array: true, default: []
      t.string   :encrypted_kms_key
      t.bigint   :expected_activity_volume
      t.string   :industry
      t.string   :intended_use
      t.string   :legal_structure
      t.string   :listed_exchange
      t.string   :naics_code
      t.string   :operating_jurisdictions, array: true, default: []
      t.string   :primary_email
      t.string   :primary_phone
      t.string   :primary_social_media_sites, array: true, default: []
      t.uuid     :public_id
      t.string   :regulator_jurisdiction
      t.string   :regulator_name
      t.string   :regulator_register_number
      t.string   :source_of_funds
      t.string   :ticker_symbol
      t.string   :wealth_source
      t.string   :website
      t.references :physical_address, foreign_key: { to_table: :addresses }, null: true
      t.references :primary_address, foreign_key: { to_table: :addresses }, null: true
      t.timestamps
    end
    add_index :businesses, :public_id, unique: true

    # 9. legal_entities (polymorphic entity → Individual/Business)
    create_table :legal_entities do |t|
      t.bigint   :entity_id
      t.string   :entity_type
      t.string   :external_id
      t.uuid     :public_id
      t.string   :role
      t.string   :risk_rating
      t.string   :status
      t.string   :vendor_id
      t.datetime :active_at
      t.datetime :closed_at
      t.datetime :discarded_at
      t.datetime :pending_at
      t.datetime :suspended_at
      t.references :program, foreign_key: true, null: true
      t.timestamps
    end
    add_index :legal_entities, [:entity_type, :entity_id]
    add_index :legal_entities, :public_id, unique: true
    add_index :legal_entities, :external_id
    add_index :legal_entities, :status
    add_index :legal_entities, :discarded_at

    # 10. legal_entity_relationships
    create_table :legal_entity_relationships do |t|
      t.string   :external_id
      t.uuid     :public_id
      t.integer  :ownership_percentage
      t.string   :relationship_types, array: true, default: []
      t.string   :title
      t.datetime :discarded_at
      t.references :parent_legal_entity, foreign_key: { to_table: :legal_entities }
      t.references :child_legal_entity, foreign_key: { to_table: :legal_entities }
      t.timestamps
    end
    add_index :legal_entity_relationships, :public_id, unique: true
    add_index :legal_entity_relationships, :discarded_at

    # 11. bank_legal_entities
    create_table :bank_legal_entities do |t|
      t.string   :entity
      t.string   :status
      t.string   :settlement_connection_legal_entity_id
      t.string   :settlement_legal_entity_id
      t.datetime :discarded_at
      t.references :legal_entity, foreign_key: true
      t.timestamps
    end
    add_index :bank_legal_entities, :discarded_at

    # 12. accounts
    create_table :accounts do |t|
      t.string   :currency
      t.string   :external_id
      t.string   :party_name
      t.uuid     :public_id
      t.uuid     :ledger_account_id
      t.uuid     :payable_ledger_account_id
      t.uuid     :receivable_ledger_account_id
      t.string   :status
      t.datetime :active_at
      t.datetime :closed_at
      t.datetime :discarded_at
      t.datetime :pending_activation_at
      t.datetime :pending_closure_at
      t.datetime :suspended_at
      t.references :legal_entity, foreign_key: true
      t.references :party_address, foreign_key: { to_table: :addresses }, null: true
      t.timestamps
    end
    add_index :accounts, :public_id, unique: true
    add_index :accounts, :external_id
    add_index :accounts, :status
    add_index :accounts, :discarded_at

    # 13. account_balances
    create_table :account_balances do |t|
      t.bigint   :available_amount, default: 0
      t.bigint   :pending_amount, default: 0
      t.bigint   :posted_amount, default: 0
      t.integer  :lock_version, default: 0
      t.datetime :effective_at
      t.references :account, foreign_key: true
      t.timestamps
    end

    # 14. settlement_accounts
    create_table :settlement_accounts do |t|
      t.string   :entity
      t.uuid     :cash_ledger_account_id
      t.uuid     :settlement_internal_account_id
      t.string   :status
      t.datetime :discarded_at
      t.references :account, foreign_key: true
      t.timestamps
    end
    add_index :settlement_accounts, :discarded_at

    # 15. program_limits
    create_table :program_limits do |t|
      t.string   :currency
      t.string   :direction
      t.string   :payment_type
      t.bigint   :limit
      t.string   :limit_ledger_account_id
      t.datetime :limit_reset_at
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :program, foreign_key: true
      t.timestamps
    end
    add_index :program_limits, :public_id, unique: true
    add_index :program_limits, :discarded_at

    # 16. account_capabilities
    create_table :account_capabilities do |t|
      t.uuid     :cash_ledger_account_id
      t.uuid     :originating_account_id
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :account, foreign_key: true
      t.references :bank_capability, foreign_key: true, null: true
      t.references :settlement_account, foreign_key: true, null: true
      t.references :program_limit, foreign_key: true, null: true
      t.timestamps
    end
    add_index :account_capabilities, :public_id, unique: true
    add_index :account_capabilities, :discarded_at

    # 17. program_entitlements
    create_table :program_entitlements do |t|
      t.string   :allowed_roles, array: true, default: []
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :bank_capability, foreign_key: true, null: true
      t.references :program_limit, foreign_key: true, null: true
      t.timestamps
    end
    add_index :program_entitlements, :public_id, unique: true
    add_index :program_entitlements, :discarded_at

    # 18. transfers
    create_table :transfers do |t|
      t.bigint   :amount
      t.string   :currency
      t.string   :external_id
      t.uuid     :public_id
      t.string   :payment_type
      t.string   :direction
      t.string   :status
      t.string   :transfer_type
      t.string   :account_role
      t.jsonb    :data, default: {}
      t.string   :settlement_id
      t.string   :failure_reason
      t.integer  :lock_version, default: 0
      t.uuid     :ledger_transaction_id
      t.datetime :approved_at
      t.datetime :cancelled_at
      t.datetime :completed_at
      t.datetime :discarded_at
      t.datetime :failed_at
      t.datetime :held_at
      t.datetime :pending_at
      t.datetime :processing_at
      t.datetime :returned_at
      t.datetime :reversed_at
      t.datetime :sent_at
      t.datetime :settlement_completed_at
      t.references :account, foreign_key: true
      t.references :account_capability, foreign_key: true, null: true
      t.timestamps
    end
    add_index :transfers, :public_id, unique: true
    add_index :transfers, :external_id
    add_index :transfers, :status
    add_index :transfers, :discarded_at

    # 19. transfer_references
    create_table :transfer_references do |t|
      t.string   :reference_type
      t.string   :reference_value
      t.string   :settlement_referenceable_id
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :transfer, foreign_key: true
      t.timestamps
    end
    add_index :transfer_references, :public_id, unique: true
    add_index :transfer_references, :discarded_at

    # 20. transfer_seasonings
    create_table :transfer_seasonings do |t|
      t.string   :status
      t.datetime :end_at
      t.datetime :discarded_at
      t.references :transfer, foreign_key: true
      t.timestamps
    end
    add_index :transfer_seasonings, :discarded_at

    # 21. books
    create_table :books do |t|
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :originating_transfer, foreign_key: { to_table: :transfers }, null: true
      t.references :receiving_transfer, foreign_key: { to_table: :transfers }, null: true
      t.timestamps
    end
    add_index :books, :public_id, unique: true
    add_index :books, :discarded_at

    # 22. returns
    create_table :returns do |t|
      t.string   :code
      t.string   :reason
      t.date     :date_of_death
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :original_transfer, foreign_key: { to_table: :transfers }, null: true
      t.references :return_transfer, foreign_key: { to_table: :transfers }, null: true
      t.timestamps
    end
    add_index :returns, :public_id, unique: true
    add_index :returns, :discarded_at

    # 23. ach_nocs
    create_table :ach_nocs do |t|
      t.string   :code
      t.string   :corrected_account_number
      t.string   :corrected_company_id
      t.string   :corrected_company_name
      t.string   :corrected_individual_identification_number
      t.string   :corrected_routing_number
      t.string   :corrected_transaction_code
      t.string   :settlement_id
      t.uuid     :public_id
      t.datetime :discarded_at
      t.references :transfer, foreign_key: true
      t.timestamps
    end
    add_index :ach_nocs, :public_id, unique: true
    add_index :ach_nocs, :discarded_at

    # 24. verifications (STI: Verification, Verification::Route, Verification::Sardine, Verification::Settlement)
    create_table :verifications do |t|
      t.string   :type
      t.string   :status
      t.string   :rejection_reason
      t.jsonb    :data, default: {}
      t.string   :vendor_id
      t.datetime :discarded_at
      t.references :transfer, foreign_key: true
      t.timestamps
    end
    add_index :verifications, :type
    add_index :verifications, :status
    add_index :verifications, :discarded_at

    # 25. decisions
    create_table :decisions do |t|
      t.string   :status
      t.jsonb    :details
      t.string   :resolved_by
      t.string   :vendor_id
      t.datetime :expires_at
      t.datetime :discarded_at
      t.references :legal_entity, foreign_key: true
      t.timestamps
    end
    add_index :decisions, :discarded_at

    # 26. evaluations
    create_table :evaluations do |t|
      t.string   :status
      t.jsonb    :details
      t.string   :resolved_by
      t.string   :vendor_id
      t.datetime :expires_at
      t.datetime :discarded_at
      t.references :decision, foreign_key: true
      t.references :legal_entity, foreign_key: true
      t.timestamps
    end
    add_index :evaluations, :discarded_at

    # 27. documents (polymorphic)
    create_table :documents do |t|
      t.string   :document_type
      t.bigint   :documentable_id
      t.string   :documentable_type
      t.uuid     :public_id
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :documents, [:documentable_type, :documentable_id]
    add_index :documents, :public_id, unique: true
    add_index :documents, :discarded_at

    # 28. identifications (polymorphic)
    create_table :identifications do |t|
      t.string   :id_type
      t.string   :id_number_ciphertext
      t.string   :encrypted_kms_key
      t.string   :issuing_country
      t.string   :issuing_region
      t.bigint   :identifiable_id
      t.string   :identifiable_type
      t.uuid     :public_id
      t.datetime :discarded_at
      t.timestamps
    end
    add_index :identifications, [:identifiable_type, :identifiable_id]
    add_index :identifications, :public_id, unique: true
    add_index :identifications, :discarded_at
  end
end
