class CreateAllTables < ActiveRecord::Migration[8.1]
  def change
    # 1. operators — no dependencies
    create_table :operators, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :name,     limit: 255, null: false
      t.string  :email,    limit: 255, null: false
      t.string  :role,     limit: 50,  null: false
      t.string  :team,     limit: 100
      t.boolean :is_agent, default: false, null: false
      t.timestamps default: -> { "now()" }
    end

    add_index :operators, :email, unique: true, name: "operators_email_key"
    execute <<~SQL
      ALTER TABLE operators ADD CONSTRAINT operators_role_check
        CHECK (role IN ('l1_ops','compliance','tam','support','bpo','ai_agent'));
    SQL

    # 2. legal_entities — FK → operators (tam_id), self-ref (parent_id)
    create_table :legal_entities, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string  :name,             limit: 255, null: false
      t.string  :status,           limit: 50,  null: false, default: "pending"
      t.string  :kyb_status,       limit: 50,  null: false, default: "not_started"
      t.string  :risk_level,       limit: 20
      t.string  :tier,             limit: 2,   null: false
      t.string  :sf_account_id,    limit: 255
      t.string  :sf_contact_email, limit: 255
      t.boolean :payment_enabled,  default: false, null: false
      t.uuid    :parent_id
      t.uuid    :tam_id
      t.timestamps default: -> { "now()" }
    end

    add_index :legal_entities, :parent_id, name: "idx_le_parent"
    add_index :legal_entities, :status,    name: "idx_le_status"
    add_index :legal_entities, :tier,      name: "idx_le_tier"
    add_foreign_key :legal_entities, :legal_entities, column: :parent_id, name: "legal_entities_parent_id_fkey", on_delete: :nullify
    add_foreign_key :legal_entities, :operators, column: :tam_id, name: "legal_entities_tam_id_fkey", on_delete: :nullify

    execute <<~SQL
      ALTER TABLE legal_entities
        ADD CONSTRAINT legal_entities_status_check CHECK (status IN ('pending','active','suspended','offboarded')),
        ADD CONSTRAINT legal_entities_kyb_status_check CHECK (kyb_status IN ('not_started','in_progress','approved','rejected','needs_review')),
        ADD CONSTRAINT legal_entities_risk_level_check CHECK (risk_level IN ('low','medium','high','critical')),
        ADD CONSTRAINT legal_entities_tier_check CHECK (tier IN ('C1','C2','C3'));
    SQL

    # 3. payment_orders — FK → legal_entities
    create_table :payment_orders, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :legal_entity_id, null: false
      t.string   :flow_order_id,   limit: 255
      t.bigint   :amount,          null: false
      t.string   :currency,        limit: 3,   null: false, default: "USD"
      t.string   :direction,       limit: 10,  null: false
      t.string   :counterparty,    limit: 255
      t.string   :status,          limit: 50,  null: false, default: "pending"
      t.string   :hold_reason,     limit: 100
      t.datetime :held_at,         precision: nil
      t.datetime :released_at,     precision: nil
      t.timestamps default: -> { "now()" }
    end

    add_index :payment_orders, :legal_entity_id, name: "idx_po_entity"
    add_index :payment_orders, :status,          name: "idx_po_status"
    add_index :payment_orders, :flow_order_id, unique: true, name: "payment_orders_flow_order_id_key"
    add_foreign_key :payment_orders, :legal_entities, name: "payment_orders_legal_entity_id_fkey", on_delete: :cascade

    execute <<~SQL
      ALTER TABLE payment_orders
        ADD CONSTRAINT payment_orders_direction_check CHECK (direction IN ('credit','debit')),
        ADD CONSTRAINT payment_orders_status_check CHECK (status IN ('pending','processing','held','completed','failed','blocked'));
    SQL

    # 4. sardine_alerts — FK → legal_entities + payment_orders
    create_table :sardine_alerts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :legal_entity_id,  null: false
      t.uuid     :payment_order_id
      t.string   :sardine_alert_id, limit: 255
      t.string   :alert_type,       limit: 50,  null: false
      t.string   :status,           limit: 50,  null: false, default: "open"
      t.decimal  :risk_score,       precision: 5, scale: 2
      t.jsonb    :details
      t.string   :sardine_case_url, limit: 500
      t.datetime :triggered_at,     precision: nil, null: false, default: -> { "now()" }
      t.datetime :resolved_at,      precision: nil
      t.timestamps default: -> { "now()" }
    end

    add_index :sardine_alerts, :legal_entity_id,              name: "idx_sa_entity"
    add_index :sardine_alerts, :payment_order_id,             name: "idx_sa_payment"
    add_index :sardine_alerts, [:alert_type, :status],        name: "idx_sa_type"
    add_index :sardine_alerts, :sardine_alert_id, unique: true, name: "sardine_alerts_sardine_alert_id_key"
    add_foreign_key :sardine_alerts, :legal_entities, name: "sardine_alerts_legal_entity_id_fkey", on_delete: :cascade
    add_foreign_key :sardine_alerts, :payment_orders, name: "sardine_alerts_payment_order_id_fkey", on_delete: :nullify

    execute <<~SQL
      ALTER TABLE sardine_alerts
        ADD CONSTRAINT sardine_alerts_alert_type_check CHECK (alert_type IN ('sanctions_hit','tm_flag','fraud_signal','wallet_screening')),
        ADD CONSTRAINT sardine_alerts_status_check CHECK (status IN ('open','under_review','cleared','confirmed','escalated'));
    SQL

    # 5. cases — FK → legal_entities, payment_orders, sardine_alerts, operators
    create_table :cases, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :legal_entity_id,  null: false
      t.uuid     :payment_order_id
      t.uuid     :sardine_alert_id
      t.uuid     :assigned_to
      t.string   :case_type,        limit: 50,  null: false
      t.string   :status,           limit: 50,  null: false, default: "open"
      t.string   :priority,         limit: 20,  null: false, default: "normal"
      t.string   :queue,            limit: 50,  null: false
      t.string   :signal_source,    limit: 50
      t.text     :reasoning
      t.string   :resolution_type,  limit: 50
      t.datetime :sla_deadline,     precision: nil
      t.datetime :resolved_at,      precision: nil
      t.string   :assigned_role,    limit: 50
      t.timestamps default: -> { "now()" }
    end

    add_index :cases, :legal_entity_id,       name: "idx_cases_entity"
    add_index :cases, :payment_order_id,      name: "idx_cases_payment"
    add_index :cases, :assigned_to,           name: "idx_cases_assigned"
    add_index :cases, [:queue, :status],      name: "idx_cases_queue_status"
    add_foreign_key :cases, :legal_entities,  name: "cases_legal_entity_id_fkey", on_delete: :cascade
    add_foreign_key :cases, :payment_orders,  name: "cases_payment_order_id_fkey", on_delete: :nullify
    add_foreign_key :cases, :sardine_alerts,  name: "cases_sardine_alert_id_fkey", on_delete: :nullify
    add_foreign_key :cases, :operators, column: :assigned_to, name: "cases_assigned_to_fkey", on_delete: :nullify

    execute <<~SQL
      ALTER TABLE cases
        ADD CONSTRAINT cases_case_type_check CHECK (case_type IN ('held_payment','onboarding','sanctions','fraud','aml')),
        ADD CONSTRAINT cases_priority_check CHECK (priority IN ('low','normal','high','critical')),
        ADD CONSTRAINT cases_queue_check CHECK (queue IN ('held_payments','onboarding','sanctions','investigations')),
        ADD CONSTRAINT cases_status_check CHECK (status IN ('open','in_review','pending_rfi','escalated','resolved','closed'));
    SQL

    # 6. case_events — FK → cases
    create_table :case_events, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid   :case_id,    null: false
      t.string :event_type, limit: 100, null: false
      t.string :actor,      limit: 255, null: false
      t.string :actor_type, limit: 20,  null: false
      t.jsonb  :details
      t.timestamps default: -> { "now()" }
    end

    add_index :case_events, :case_id, name: "idx_ce_case"
    add_foreign_key :case_events, :cases, name: "case_events_case_id_fkey", on_delete: :cascade

    execute <<~SQL
      ALTER TABLE case_events ADD CONSTRAINT case_events_actor_type_check
        CHECK (actor_type IN ('human','agent','system'));
    SQL

    # 7. rfis — FK → cases + legal_entities
    create_table :rfis, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :case_id,          null: false
      t.uuid     :legal_entity_id,  null: false
      t.string   :template_type,    limit: 100, null: false
      t.string   :channel,          limit: 50,  null: false, default: "persona_link"
      t.string   :status,           limit: 50,  null: false, default: "pending"
      t.string   :persona_link_id,  limit: 255
      t.datetime :sent_at,          precision: nil
      t.datetime :responded_at,     precision: nil
      t.datetime :expires_at,       precision: nil
      t.timestamps default: -> { "now()" }
    end

    add_index :rfis, :case_id,         name: "idx_rfis_case"
    add_index :rfis, :legal_entity_id, name: "idx_rfis_entity"
    add_index :rfis, :status,          name: "idx_rfis_status"
    add_foreign_key :rfis, :cases,          name: "rfis_case_id_fkey", on_delete: :cascade
    add_foreign_key :rfis, :legal_entities, name: "rfis_legal_entity_id_fkey", on_delete: :cascade

    execute <<~SQL
      ALTER TABLE rfis
        ADD CONSTRAINT rfis_channel_check CHECK (channel IN ('persona_link','email','sms')),
        ADD CONSTRAINT rfis_status_check CHECK (status IN ('pending','sent','responded','expired','cancelled')),
        ADD CONSTRAINT rfis_template_type_check CHECK (template_type IN ('source_of_funds','proof_of_address','ubo_documentation','transaction_purpose','custom'));
    SQL

    # 8. persona_inquiries — FK → legal_entities
    create_table :persona_inquiries, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.uuid     :legal_entity_id,     null: false
      t.string   :persona_inquiry_id,  limit: 255, null: false
      t.string   :inquiry_type,        limit: 50,  null: false
      t.string   :status,              limit: 50,  null: false, default: "created"
      t.jsonb    :result
      t.datetime :completed_at,        precision: nil
      t.timestamps default: -> { "now()" }
    end

    add_index :persona_inquiries, :legal_entity_id,     name: "idx_pi_entity"
    add_index :persona_inquiries, :status,              name: "idx_pi_status"
    add_index :persona_inquiries, :persona_inquiry_id, unique: true, name: "persona_inquiries_persona_inquiry_id_key"
    add_foreign_key :persona_inquiries, :legal_entities, name: "persona_inquiries_legal_entity_id_fkey", on_delete: :cascade

    execute <<~SQL
      ALTER TABLE persona_inquiries
        ADD CONSTRAINT persona_inquiries_inquiry_type_check CHECK (inquiry_type IN ('kyb','kyc','ubo')),
        ADD CONSTRAINT persona_inquiries_status_check CHECK (status IN ('created','pending','completed','expired','failed'));
    SQL
  end
end
