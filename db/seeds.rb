# frozen_string_literal: true

puts "Seeding compliance-monitor demo data..."

# ── 1. Operators (5) ─────────────────────────────────────────────────────────
ops = [
  { name: "Alice Martin",    email: "alice.martin@company.com",  role: "l1_ops",     team: "Operations EU" },
  { name: "Bob Chen",        email: "bob.chen@company.com",      role: "compliance",  team: "Compliance" },
  { name: "Clara López",     email: "clara.lopez@company.com",   role: "tam",         team: "Account Management" },
  { name: "David Novak",     email: "david.novak@company.com",   role: "l1_ops",      team: "Operations US" },
  { name: "Sentinel AI",     email: "sentinel@agents.internal",  role: "ai_agent",    team: "AI Agents", is_agent: true },
]
operators = ops.map { |attrs| Operator.find_or_create_by!(email: attrs[:email]) { |o| o.assign_attributes(attrs) } }
alice, bob, clara, david, sentinel = operators

puts "  ✓ #{Operator.count} operators"

# ── 2. Legal Entities (15) ───────────────────────────────────────────────────
# 3 parents
parent_attrs = [
  { name: "Acme Holdings Ltd",    status: "active",    kyb_status: "approved",     risk_level: "low",      tier: "C1", payment_enabled: true,  tam: clara },
  { name: "GlobalTrade Corp",     status: "active",    kyb_status: "approved",     risk_level: "medium",   tier: "C2", payment_enabled: true,  tam: clara },
  { name: "NovaPay Group",        status: "pending",   kyb_status: "in_progress",  risk_level: "high",     tier: "C3", payment_enabled: false, tam: clara },
]
parents = parent_attrs.map do |attrs|
  tam = attrs.delete(:tam)
  LegalEntity.find_or_create_by!(name: attrs[:name]) { |le| le.assign_attributes(attrs.merge(tam_id: tam.id)) }
end

# 12 children (4 per parent)
children_data = [
  # Acme children
  { name: "Acme Payments EU",     status: "active",    kyb_status: "approved",     risk_level: "low",    tier: "C1", payment_enabled: true,  parent: parents[0], tam: clara },
  { name: "Acme Payments US",     status: "active",    kyb_status: "approved",     risk_level: "low",    tier: "C1", payment_enabled: true,  parent: parents[0], tam: clara },
  { name: "Acme Digital Wallet",  status: "active",    kyb_status: "approved",     risk_level: "medium", tier: "C1", payment_enabled: true,  parent: parents[0], tam: clara },
  { name: "Acme Lending",         status: "suspended", kyb_status: "needs_review", risk_level: "high",   tier: "C2", payment_enabled: false, parent: parents[0], tam: clara },
  # GlobalTrade children
  { name: "GT Europe SARL",       status: "active",    kyb_status: "approved",     risk_level: "medium", tier: "C2", payment_enabled: true,  parent: parents[1], tam: clara },
  { name: "GT Asia Pte Ltd",      status: "active",    kyb_status: "approved",     risk_level: "medium", tier: "C2", payment_enabled: true,  parent: parents[1], tam: clara },
  { name: "GT Latam SA",          status: "pending",   kyb_status: "in_progress",  risk_level: nil,      tier: "C2", payment_enabled: false, parent: parents[1], tam: clara },
  { name: "GT Crypto Services",   status: "suspended", kyb_status: "rejected",     risk_level: "critical", tier: "C3", payment_enabled: false, parent: parents[1], tam: clara },
  # NovaPay children
  { name: "NovaPay FR",           status: "pending",   kyb_status: "in_progress",  risk_level: nil,      tier: "C3", payment_enabled: false, parent: parents[2], tam: clara },
  { name: "NovaPay DE",           status: "pending",   kyb_status: "not_started",  risk_level: nil,      tier: "C3", payment_enabled: false, parent: parents[2], tam: clara },
  { name: "NovaPay UK",           status: "active",    kyb_status: "approved",     risk_level: "low",    tier: "C2", payment_enabled: true,  parent: parents[2], tam: clara },
  { name: "NovaPay Crypto",       status: "offboarded", kyb_status: "rejected",    risk_level: "critical", tier: "C3", payment_enabled: false, parent: parents[2], tam: clara },
]
children = children_data.map do |attrs|
  parent = attrs.delete(:parent)
  tam = attrs.delete(:tam)
  LegalEntity.find_or_create_by!(name: attrs[:name]) { |le| le.assign_attributes(attrs.merge(parent_id: parent.id, tam_id: tam.id)) }
end

all_entities = parents + children
puts "  ✓ #{LegalEntity.count} legal entities"

# ── 3. Payment Orders (14) ──────────────────────────────────────────────────
po_data = [
  { entity: "Acme Payments EU",   flow: "FO-2026-001", amount: 150_000, currency: "EUR", direction: "credit",  counterparty: "Supplier GmbH",       status: "completed" },
  { entity: "Acme Payments EU",   flow: "FO-2026-002", amount: 500_000, currency: "EUR", direction: "debit",   counterparty: "Client SA",           status: "completed" },
  { entity: "Acme Payments US",   flow: "FO-2026-003", amount: 75_000,  currency: "USD", direction: "credit",  counterparty: "Tech Solutions Inc",  status: "pending" },
  { entity: "Acme Digital Wallet", flow: "FO-2026-004", amount: 1_200_000, currency: "USD", direction: "credit", counterparty: "Unknown LLC",       status: "held", hold_reason: "amount_threshold", held_at: 2.hours.ago },
  { entity: "GT Europe SARL",     flow: "FO-2026-005", amount: 320_000, currency: "EUR", direction: "debit",   counterparty: "Logistics BV",       status: "completed" },
  { entity: "GT Europe SARL",     flow: "FO-2026-006", amount: 89_000,  currency: "EUR", direction: "credit",  counterparty: "Raw Materials Ltd",   status: "processing" },
  { entity: "GT Asia Pte Ltd",    flow: "FO-2026-007", amount: 2_500_000, currency: "USD", direction: "credit", counterparty: "Sanctioned Corp",   status: "blocked", hold_reason: "sanctions_match" },
  { entity: "GT Asia Pte Ltd",    flow: "FO-2026-008", amount: 45_000,  currency: "SGD", direction: "debit",   counterparty: "Office Supplies Pte", status: "completed" },
  { entity: "GT Crypto Services", flow: "FO-2026-009", amount: 780_000, currency: "USD", direction: "credit",  counterparty: "DeFi Protocol X",    status: "held", hold_reason: "high_risk_entity", held_at: 1.day.ago },
  { entity: "NovaPay UK",         flow: "FO-2026-010", amount: 200_000, currency: "GBP", direction: "debit",   counterparty: "British Retail Co",   status: "completed" },
  { entity: "NovaPay UK",         flow: "FO-2026-011", amount: 55_000,  currency: "GBP", direction: "credit",  counterparty: "Suspicious Trader",   status: "held", hold_reason: "fraud_signal", held_at: 6.hours.ago },
  { entity: "Acme Lending",       flow: "FO-2026-012", amount: 3_000_000, currency: "USD", direction: "credit", counterparty: "Offshore Trust",    status: "held", hold_reason: "aml_review", held_at: 3.days.ago },
  { entity: "GT Latam SA",        flow: "FO-2026-013", amount: 120_000, currency: "USD", direction: "debit",   counterparty: "Import Export SA",    status: "pending" },
  { entity: "Acme Holdings Ltd",  flow: "FO-2026-014", amount: 950_000, currency: "EUR", direction: "credit",  counterparty: "Intercompany Transfer", status: "completed" },
]
entity_map = all_entities.index_by(&:name)
payment_orders = po_data.map do |attrs|
  entity = entity_map[attrs.delete(:entity)]
  flow = attrs.delete(:flow)
  PaymentOrder.find_or_create_by!(flow_order_id: flow) { |po| po.assign_attributes(attrs.merge(legal_entity_id: entity.id)) }
end

puts "  ✓ #{PaymentOrder.count} payment orders"

# ── 4. Sardine Alerts (4) ───────────────────────────────────────────────────
po_map = payment_orders.index_by(&:flow_order_id)

alert_data = [
  {
    entity: "GT Asia Pte Ltd", payment_flow: "FO-2026-007",
    sardine_alert_id: "SA-9001", alert_type: "sanctions_hit", status: "open", risk_score: 95.0,
    sardine_case_url: "https://app.sardine.ai/cases/SA-9001",
    details: { matched_list: "OFAC SDN", matched_name: "Sanctioned Corp Ltd", score: 95 }
  },
  {
    entity: "NovaPay UK", payment_flow: "FO-2026-011",
    sardine_alert_id: "SA-9002", alert_type: "fraud_signal", status: "under_review", risk_score: 78.5,
    sardine_case_url: "https://app.sardine.ai/cases/SA-9002",
    details: { signal: "velocity_spike", transactions_1h: 42, avg_transactions_1h: 3 }
  },
  {
    entity: "GT Crypto Services", payment_flow: "FO-2026-009",
    sardine_alert_id: "SA-9003", alert_type: "wallet_screening", status: "escalated", risk_score: 88.0,
    sardine_case_url: "https://app.sardine.ai/cases/SA-9003",
    details: { wallet: "0xdead...beef", mixer_exposure_pct: 34, darknet_exposure_pct: 12 }
  },
  {
    entity: "Acme Lending", payment_flow: "FO-2026-012",
    sardine_alert_id: "SA-9004", alert_type: "tm_flag", status: "open", risk_score: 65.0,
    sardine_case_url: "https://app.sardine.ai/cases/SA-9004",
    details: { pattern: "structuring", total_7d: 3_000_000, transaction_count: 12, avg_amount: 250_000 }
  },
]
sardine_alerts = alert_data.map do |attrs|
  entity = entity_map[attrs.delete(:entity)]
  po = po_map[attrs.delete(:payment_flow)]
  sid = attrs[:sardine_alert_id]
  SardineAlert.find_or_create_by!(sardine_alert_id: sid) do |sa|
    sa.assign_attributes(attrs.merge(legal_entity_id: entity.id, payment_order_id: po&.id))
  end
end

puts "  ✓ #{SardineAlert.count} sardine alerts"

# ── 5. Investigation Cases (8) ──────────────────────────────────────────────
sa_map = sardine_alerts.index_by(&:sardine_alert_id)

case_data = [
  { entity: "GT Asia Pte Ltd",    po_flow: "FO-2026-007", sa_id: "SA-9001", assigned: bob,      case_type: "sanctions",     status: "open",       priority: "critical", queue: "sanctions",       signal_source: "sardine",   sla_deadline: 4.hours.from_now, assigned_role: "compliance" },
  { entity: "NovaPay UK",         po_flow: "FO-2026-011", sa_id: "SA-9002", assigned: alice,    case_type: "fraud",         status: "in_review",  priority: "high",     queue: "investigations", signal_source: "sardine",   sla_deadline: 8.hours.from_now, assigned_role: "l1_ops" },
  { entity: "GT Crypto Services", po_flow: "FO-2026-009", sa_id: "SA-9003", assigned: bob,      case_type: "aml",           status: "escalated",  priority: "critical", queue: "investigations", signal_source: "sardine",   sla_deadline: 2.hours.from_now, assigned_role: "compliance" },
  { entity: "Acme Lending",       po_flow: "FO-2026-012", sa_id: "SA-9004", assigned: sentinel, case_type: "aml",           status: "open",       priority: "high",     queue: "investigations", signal_source: "sardine",   sla_deadline: 12.hours.from_now, assigned_role: "ai_agent" },
  { entity: "Acme Digital Wallet", po_flow: "FO-2026-004", sa_id: nil,      assigned: alice,    case_type: "held_payment",  status: "open",       priority: "normal",   queue: "held_payments",  signal_source: "flow",      sla_deadline: 24.hours.from_now, assigned_role: "l1_ops" },
  { entity: "NovaPay FR",         po_flow: nil,            sa_id: nil,      assigned: david,    case_type: "onboarding",    status: "pending_rfi", priority: "normal",  queue: "onboarding",     signal_source: "ops_queue", sla_deadline: 3.days.from_now, assigned_role: "l1_ops" },
  { entity: "GT Latam SA",        po_flow: nil,            sa_id: nil,      assigned: nil,      case_type: "onboarding",    status: "open",       priority: "low",      queue: "onboarding",     signal_source: "ops_queue", sla_deadline: 5.days.from_now },
  { entity: "NovaPay Crypto",     po_flow: nil,            sa_id: nil,      assigned: bob,      case_type: "aml",           status: "resolved",   priority: "high",     queue: "investigations", signal_source: "manual",    resolved_at: 2.days.ago, resolution_type: "offboarded", reasoning: "Entity failed KYB and has critical risk exposure. Recommended offboarding.", assigned_role: "compliance" },
]
cases = case_data.map do |attrs|
  entity = entity_map[attrs.delete(:entity)]
  po = attrs.delete(:po_flow) ? po_map[attrs[:po_flow]] || po_map[attrs.delete(:po_flow)] : (attrs.delete(:po_flow); nil)
  sa = attrs.delete(:sa_id) ? sa_map[attrs[:sa_id]] || sa_map.values.find { |s| s.sardine_alert_id == attrs.delete(:sa_id) } : nil
  assigned = attrs.delete(:assigned)
  # clean up any leftover keys
  attrs.delete(:po_flow)
  attrs.delete(:sa_id)

  InvestigationCase.create!(
    attrs.merge(
      legal_entity_id: entity.id,
      payment_order_id: po&.id,
      sardine_alert_id: sa&.id,
      assigned_to: assigned&.id
    )
  )
end

puts "  ✓ #{InvestigationCase.count} cases"

# ── 6. Case Events (16) ─────────────────────────────────────────────────────
events = [
  # Case 0 — sanctions (GT Asia)
  { case_idx: 0, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "sardine_webhook", alert_id: "SA-9001" } },
  { case_idx: 0, event_type: "assigned",      actor: "system",             actor_type: "system", details: { assigned_to: bob.name, reason: "sanctions_queue_routing" } },
  # Case 1 — fraud (NovaPay UK)
  { case_idx: 1, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "sardine_webhook", alert_id: "SA-9002" } },
  { case_idx: 1, event_type: "assigned",      actor: "system",             actor_type: "system", details: { assigned_to: alice.name } },
  { case_idx: 1, event_type: "status_change", actor: alice.name,           actor_type: "human",  details: { from: "open", to: "in_review" } },
  { case_idx: 1, event_type: "note_added",    actor: alice.name,           actor_type: "human",  details: { note: "Reviewing velocity spike — looks like a batch processing error, not fraud." } },
  # Case 2 — AML (GT Crypto)
  { case_idx: 2, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "sardine_webhook", alert_id: "SA-9003" } },
  { case_idx: 2, event_type: "assigned",      actor: "system",             actor_type: "system", details: { assigned_to: bob.name } },
  { case_idx: 2, event_type: "status_change", actor: bob.name,             actor_type: "human",  details: { from: "open", to: "escalated", reason: "High mixer exposure requires senior review" } },
  # Case 3 — AML (Acme Lending) — AI-handled
  { case_idx: 3, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "sardine_webhook", alert_id: "SA-9004" } },
  { case_idx: 3, event_type: "assigned",      actor: "system",             actor_type: "agent",  details: { assigned_to: sentinel.name, reason: "auto_triage" } },
  { case_idx: 3, event_type: "analysis",      actor: sentinel.name,        actor_type: "agent",  details: { summary: "Structuring pattern detected. 12 transactions totaling $3M in 7 days, consistent with layering.", recommendation: "escalate_to_compliance" } },
  # Case 4 — held payment (Acme Digital Wallet)
  { case_idx: 4, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "flow_hold_webhook", reason: "amount_threshold" } },
  { case_idx: 4, event_type: "assigned",      actor: "system",             actor_type: "system", details: { assigned_to: alice.name } },
  # Case 7 — resolved (NovaPay Crypto)
  { case_idx: 7, event_type: "created",       actor: "system",             actor_type: "system", details: { source: "manual" } },
  { case_idx: 7, event_type: "resolved",      actor: bob.name,             actor_type: "human",  details: { resolution: "offboarded", note: "Entity offboarded due to critical risk and failed KYB." } },
]
events.each do |attrs|
  c = cases[attrs.delete(:case_idx)]
  CaseEvent.create!(attrs.merge(case_id: c.id))
end

puts "  ✓ #{CaseEvent.count} case events"

# ── 7. RFIs (1) ─────────────────────────────────────────────────────────────
Rfi.create!(
  case_id: cases[5].id,       # NovaPay FR onboarding case
  legal_entity_id: entity_map["NovaPay FR"].id,
  template_type: "ubo_documentation",
  channel: "persona_link",
  status: "sent",
  persona_link_id: "pl_live_abc123",
  sent_at: 1.day.ago,
  expires_at: 6.days.from_now
)

puts "  ✓ #{Rfi.count} RFIs"

# ── 8. Persona Inquiries (4) ────────────────────────────────────────────────
inquiries = [
  { entity: "NovaPay FR",        persona_inquiry_id: "inq_kyb_001", inquiry_type: "kyb", status: "pending" },
  { entity: "GT Latam SA",       persona_inquiry_id: "inq_kyb_002", inquiry_type: "kyb", status: "created" },
  { entity: "NovaPay Crypto",    persona_inquiry_id: "inq_kyc_003", inquiry_type: "kyc", status: "failed",    result: { reason: "document_expired" }, completed_at: 5.days.ago },
  { entity: "Acme Lending",      persona_inquiry_id: "inq_ubo_004", inquiry_type: "ubo", status: "completed", result: { ubo_count: 2, verified: true }, completed_at: 10.days.ago },
]
inquiries.each do |attrs|
  entity = entity_map[attrs.delete(:entity)]
  pid = attrs[:persona_inquiry_id]
  PersonaInquiry.find_or_create_by!(persona_inquiry_id: pid) do |pi|
    pi.assign_attributes(attrs.merge(legal_entity_id: entity.id))
  end
end

puts "  ✓ #{PersonaInquiry.count} persona inquiries"
puts "Done! 🎉"
