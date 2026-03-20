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

ActiveRecord::Schema[8.1].define(version: 2026_03_20_000001) do
  create_schema "extensions"

  # These are extensions that must be enabled in order to support this database
  enable_extension "extensions.pg_stat_statements"
  enable_extension "extensions.pgcrypto"
  enable_extension "extensions.uuid-ossp"
  enable_extension "graphql.pg_graphql"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "vault.supabase_vault"

  create_table "public.case_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "actor", limit: 255, null: false
    t.string "actor_type", limit: 20, null: false
    t.uuid "case_id", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.jsonb "details"
    t.string "event_type", limit: 100, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["case_id"], name: "idx_ce_case"
    t.check_constraint "actor_type::text = ANY (ARRAY['human'::character varying, 'agent'::character varying, 'system'::character varying]::text[])", name: "case_events_actor_type_check"
  end

  create_table "public.cases", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "assigned_role", limit: 50
    t.uuid "assigned_to"
    t.string "case_type", limit: 50, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.uuid "legal_entity_id", null: false
    t.uuid "payment_order_id"
    t.string "priority", limit: 20, default: "normal", null: false
    t.string "queue", limit: 50, null: false
    t.text "reasoning"
    t.string "resolution_type", limit: 50
    t.datetime "resolved_at", precision: nil
    t.uuid "sardine_alert_id"
    t.string "signal_source", limit: 50
    t.datetime "sla_deadline", precision: nil
    t.string "status", limit: 50, default: "open", null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["assigned_to"], name: "idx_cases_assigned"
    t.index ["legal_entity_id"], name: "idx_cases_entity"
    t.index ["payment_order_id"], name: "idx_cases_payment"
    t.index ["queue", "status"], name: "idx_cases_queue_status"
    t.check_constraint "case_type::text = ANY (ARRAY['held_payment'::character varying, 'onboarding'::character varying, 'sanctions'::character varying, 'fraud'::character varying, 'aml'::character varying]::text[])", name: "cases_case_type_check"
    t.check_constraint "priority::text = ANY (ARRAY['low'::character varying, 'normal'::character varying, 'high'::character varying, 'critical'::character varying]::text[])", name: "cases_priority_check"
    t.check_constraint "queue::text = ANY (ARRAY['held_payments'::character varying, 'onboarding'::character varying, 'sanctions'::character varying, 'investigations'::character varying]::text[])", name: "cases_queue_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'in_review'::character varying, 'pending_rfi'::character varying, 'escalated'::character varying, 'resolved'::character varying, 'closed'::character varying]::text[])", name: "cases_status_check"
  end

  create_table "public.legal_entities", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "kyb_status", limit: 50, default: "not_started", null: false
    t.string "name", limit: 255, null: false
    t.uuid "parent_id"
    t.boolean "payment_enabled", default: false, null: false
    t.string "risk_level", limit: 20
    t.string "sf_account_id", limit: 255
    t.string "sf_contact_email", limit: 255
    t.string "status", limit: 50, default: "pending", null: false
    t.uuid "tam_id"
    t.string "tier", limit: 2, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["parent_id"], name: "idx_le_parent"
    t.index ["status"], name: "idx_le_status"
    t.index ["tier"], name: "idx_le_tier"
    t.check_constraint "kyb_status::text = ANY (ARRAY['not_started'::character varying, 'in_progress'::character varying, 'approved'::character varying, 'rejected'::character varying, 'needs_review'::character varying]::text[])", name: "legal_entities_kyb_status_check"
    t.check_constraint "risk_level::text = ANY (ARRAY['low'::character varying, 'medium'::character varying, 'high'::character varying, 'critical'::character varying]::text[])", name: "legal_entities_risk_level_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'active'::character varying, 'suspended'::character varying, 'offboarded'::character varying]::text[])", name: "legal_entities_status_check"
    t.check_constraint "tier::text = ANY (ARRAY['C1'::character varying, 'C2'::character varying, 'C3'::character varying]::text[])", name: "legal_entities_tier_check"
  end

  create_table "public.matthieu", id: :bigint, default: nil, force: :cascade do |t|
    t.timestamptz "created_at", default: -> { "now()" }, null: false
  end

  create_table "public.operators", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "email", limit: 255, null: false
    t.boolean "is_agent", default: false, null: false
    t.string "name", limit: 255, null: false
    t.string "role", limit: 50, null: false
    t.string "team", limit: 100
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["email"], name: "operators_email_key", unique: true
    t.check_constraint "role::text = ANY (ARRAY['l1_ops'::character varying, 'compliance'::character varying, 'tam'::character varying, 'support'::character varying, 'bpo'::character varying, 'ai_agent'::character varying]::text[])", name: "operators_role_check"
  end

  create_table "public.payment_orders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.bigint "amount", null: false
    t.string "counterparty", limit: 255
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "currency", limit: 3, default: "USD", null: false
    t.string "direction", limit: 10, null: false
    t.string "flow_order_id", limit: 255
    t.datetime "held_at", precision: nil
    t.string "hold_reason", limit: 100
    t.uuid "legal_entity_id", null: false
    t.datetime "released_at", precision: nil
    t.string "status", limit: 50, default: "pending", null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["flow_order_id"], name: "payment_orders_flow_order_id_key", unique: true
    t.index ["legal_entity_id"], name: "idx_po_entity"
    t.index ["status"], name: "idx_po_status"
    t.check_constraint "direction::text = ANY (ARRAY['credit'::character varying, 'debit'::character varying]::text[])", name: "payment_orders_direction_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'processing'::character varying, 'held'::character varying, 'completed'::character varying, 'failed'::character varying, 'blocked'::character varying]::text[])", name: "payment_orders_status_check"
  end

  create_table "public.persona_inquiries", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.datetime "completed_at", precision: nil
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.string "inquiry_type", limit: 50, null: false
    t.uuid "legal_entity_id", null: false
    t.string "persona_inquiry_id", limit: 255, null: false
    t.jsonb "result"
    t.string "status", limit: 50, default: "created", null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["legal_entity_id"], name: "idx_pi_entity"
    t.index ["persona_inquiry_id"], name: "persona_inquiries_persona_inquiry_id_key", unique: true
    t.index ["status"], name: "idx_pi_status"
    t.check_constraint "inquiry_type::text = ANY (ARRAY['kyb'::character varying, 'kyc'::character varying, 'ubo'::character varying]::text[])", name: "persona_inquiries_inquiry_type_check"
    t.check_constraint "status::text = ANY (ARRAY['created'::character varying, 'pending'::character varying, 'completed'::character varying, 'expired'::character varying, 'failed'::character varying]::text[])", name: "persona_inquiries_status_check"
  end

  create_table "public.rfis", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "case_id", null: false
    t.string "channel", limit: 50, default: "persona_link", null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.datetime "expires_at", precision: nil
    t.uuid "legal_entity_id", null: false
    t.string "persona_link_id", limit: 255
    t.datetime "responded_at", precision: nil
    t.datetime "sent_at", precision: nil
    t.string "status", limit: 50, default: "pending", null: false
    t.string "template_type", limit: 100, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["case_id"], name: "idx_rfis_case"
    t.index ["legal_entity_id"], name: "idx_rfis_entity"
    t.index ["status"], name: "idx_rfis_status"
    t.check_constraint "channel::text = ANY (ARRAY['persona_link'::character varying, 'email'::character varying, 'sms'::character varying]::text[])", name: "rfis_channel_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'sent'::character varying, 'responded'::character varying, 'expired'::character varying, 'cancelled'::character varying]::text[])", name: "rfis_status_check"
    t.check_constraint "template_type::text = ANY (ARRAY['source_of_funds'::character varying, 'proof_of_address'::character varying, 'ubo_documentation'::character varying, 'transaction_purpose'::character varying, 'custom'::character varying]::text[])", name: "rfis_template_type_check"
  end

  create_table "public.sardine_alerts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "alert_type", limit: 50, null: false
    t.datetime "created_at", default: -> { "now()" }, null: false
    t.jsonb "details"
    t.uuid "legal_entity_id", null: false
    t.uuid "payment_order_id"
    t.datetime "resolved_at", precision: nil
    t.decimal "risk_score", precision: 5, scale: 2
    t.string "sardine_alert_id", limit: 255
    t.string "sardine_case_url", limit: 500
    t.string "status", limit: 50, default: "open", null: false
    t.datetime "triggered_at", precision: nil, default: -> { "now()" }, null: false
    t.datetime "updated_at", default: -> { "now()" }, null: false
    t.index ["alert_type", "status"], name: "idx_sa_type"
    t.index ["legal_entity_id"], name: "idx_sa_entity"
    t.index ["payment_order_id"], name: "idx_sa_payment"
    t.index ["sardine_alert_id"], name: "sardine_alerts_sardine_alert_id_key", unique: true
    t.check_constraint "alert_type::text = ANY (ARRAY['sanctions_hit'::character varying, 'tm_flag'::character varying, 'fraud_signal'::character varying, 'wallet_screening'::character varying]::text[])", name: "sardine_alerts_alert_type_check"
    t.check_constraint "status::text = ANY (ARRAY['open'::character varying, 'under_review'::character varying, 'cleared'::character varying, 'confirmed'::character varying, 'escalated'::character varying]::text[])", name: "sardine_alerts_status_check"
  end

  add_foreign_key "public.case_events", "public.cases", name: "case_events_case_id_fkey", on_delete: :cascade
  add_foreign_key "public.cases", "public.legal_entities", name: "cases_legal_entity_id_fkey", on_delete: :cascade
  add_foreign_key "public.cases", "public.operators", column: "assigned_to", name: "cases_assigned_to_fkey", on_delete: :nullify
  add_foreign_key "public.cases", "public.payment_orders", name: "cases_payment_order_id_fkey", on_delete: :nullify
  add_foreign_key "public.cases", "public.sardine_alerts", name: "cases_sardine_alert_id_fkey", on_delete: :nullify
  add_foreign_key "public.legal_entities", "public.legal_entities", column: "parent_id", name: "legal_entities_parent_id_fkey", on_delete: :nullify
  add_foreign_key "public.legal_entities", "public.operators", column: "tam_id", name: "legal_entities_tam_id_fkey", on_delete: :nullify
  add_foreign_key "public.payment_orders", "public.legal_entities", name: "payment_orders_legal_entity_id_fkey", on_delete: :cascade
  add_foreign_key "public.persona_inquiries", "public.legal_entities", name: "persona_inquiries_legal_entity_id_fkey", on_delete: :cascade
  add_foreign_key "public.rfis", "public.cases", name: "rfis_case_id_fkey", on_delete: :cascade
  add_foreign_key "public.rfis", "public.legal_entities", name: "rfis_legal_entity_id_fkey", on_delete: :cascade
  add_foreign_key "public.sardine_alerts", "public.legal_entities", name: "sardine_alerts_legal_entity_id_fkey", on_delete: :cascade
  add_foreign_key "public.sardine_alerts", "public.payment_orders", name: "sardine_alerts_payment_order_id_fkey", on_delete: :nullify

end
