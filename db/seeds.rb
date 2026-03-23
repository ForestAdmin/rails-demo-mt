# frozen_string_literal: true

puts "Seeding Modern Treasury demo data..."

# ---------------------------------------------------------------------------
# 1. Addresses (5)
# ---------------------------------------------------------------------------
addresses = [
  { line1: "350 Fifth Avenue", line2: "Suite 3200", locality: "New York", region: "NY", postal_code: "10118", country_code: "US" },
  { line1: "1 Market Street", line2: "Floor 40", locality: "San Francisco", region: "CA", postal_code: "94105", country_code: "US" },
  { line1: "200 Clarendon Street", locality: "Boston", region: "MA", postal_code: "02116", country_code: "US" },
  { line1: "25 Old Broad Street", line2: "Floor 10", locality: "London", postal_code: "EC2N 1HN", country_code: "GB" },
  { line1: "100 Congress Avenue", line2: "Suite 1500", locality: "Austin", region: "TX", postal_code: "78701", country_code: "US" },
].map { |attrs| Address.find_or_create_by!(line1: attrs[:line1], locality: attrs[:locality]) { |a| a.assign_attributes(attrs) } }

puts "  ✓ Addresses: #{Address.count}"

# ---------------------------------------------------------------------------
# 2. Programs (2)
# ---------------------------------------------------------------------------
standard_program = Program.find_or_create_by!(name: "Standard Payments") { |p| p.public_id = SecureRandom.uuid }
crypto_program = Program.find_or_create_by!(name: "Crypto Operations") { |p| p.public_id = SecureRandom.uuid }
puts "  ✓ Programs: #{Program.count}"

# ---------------------------------------------------------------------------
# 3. Bank Capabilities (3)
# ---------------------------------------------------------------------------
ach_cap = BankCapability.find_or_create_by!(payment_type: "ach", currency: "USD", direction: "credit") { |b| b.limit = 10_000_000 }
wire_cap = BankCapability.find_or_create_by!(payment_type: "wire", currency: "USD", direction: "credit") { |b| b.limit = 50_000_000 }
rtp_cap = BankCapability.find_or_create_by!(payment_type: "rtp", currency: "USD", direction: "credit") { |b| b.limit = 5_000_000 }
puts "  ✓ BankCapabilities: #{BankCapability.count}"

# ---------------------------------------------------------------------------
# 4. Individuals (4)
# ---------------------------------------------------------------------------
individuals = [
  { first_name: "Elena", last_name: "Rodriguez", primary_email: "elena.rodriguez@example.com", primary_phone: "+12125551001", date_of_birth: Date.new(1985, 3, 14), citizenship_country_code: "US", primary_address: addresses[0] },
  { first_name: "James", last_name: "Chen", primary_email: "james.chen@example.com", primary_phone: "+14155551002", date_of_birth: Date.new(1990, 7, 22), citizenship_country_code: "US", primary_address: addresses[1] },
  { first_name: "Priya", last_name: "Sharma", primary_email: "priya.sharma@example.com", primary_phone: "+16175551003", date_of_birth: Date.new(1988, 11, 5), citizenship_country_code: "GB", primary_address: addresses[3] },
  { first_name: "Michael", last_name: "Thompson", primary_email: "michael.thompson@example.com", primary_phone: "+15125551004", date_of_birth: Date.new(1975, 1, 30), citizenship_country_code: "US", primary_address: addresses[4] },
].map { |attrs| Individual.find_or_create_by!(primary_email: attrs[:primary_email]) { |i| i.assign_attributes(attrs.merge(public_id: SecureRandom.uuid)) } }

puts "  ✓ Individuals: #{Individual.count}"

# ---------------------------------------------------------------------------
# 5. Businesses (3)
# ---------------------------------------------------------------------------
businesses = [
  { business_name: "Meridian Fintech LLC", doing_business_as_names: ["Meridian Pay", "MeridianFT"], website: "https://meridianfintech.example.com", country_of_incorporation: "US", legal_structure: "llc", physical_address: addresses[0], primary_address: addresses[0] },
  { business_name: "Atlas Global Trading Ltd", doing_business_as_names: ["Atlas Trading"], website: "https://atlasglobal.example.com", country_of_incorporation: "GB", legal_structure: "corporation", physical_address: addresses[3], primary_address: addresses[3] },
  { business_name: "Beacon Digital Assets Inc", doing_business_as_names: ["Beacon Crypto", "Beacon Digital"], website: "https://beacondigital.example.com", country_of_incorporation: "US", legal_structure: "corporation", physical_address: addresses[1], primary_address: addresses[1] },
].map { |attrs| Business.find_or_create_by!(business_name: attrs[:business_name]) { |b| b.assign_attributes(attrs.merge(public_id: SecureRandom.uuid)) } }

puts "  ✓ Businesses: #{Business.count}"

# ---------------------------------------------------------------------------
# 6. Legal Entities (7)
# ---------------------------------------------------------------------------
legal_entities = []

# Individual-backed
individuals.each_with_index do |ind, i|
  le = LegalEntity.find_or_create_by!(entity: ind) do |l|
    l.public_id = SecureRandom.uuid
    l.program = [standard_program, crypto_program][i % 2]
    l.status = "active"
    l.role = "standard"
    l.risk_rating = "low"
  end
  legal_entities << le
end

# Business-backed
businesses.each_with_index do |biz, i|
  le = LegalEntity.find_or_create_by!(entity: biz) do |l|
    l.public_id = SecureRandom.uuid
    l.program = [standard_program, crypto_program][i % 2]
    l.status = "active"
    l.role = "standard"
    l.risk_rating = %w[low medium high][i]
  end
  legal_entities << le
end

puts "  ✓ LegalEntities: #{LegalEntity.count}"

# ---------------------------------------------------------------------------
# 7. Legal Entity Relationships (3)
# ---------------------------------------------------------------------------
[
  { parent_legal_entity: legal_entities[4], child_legal_entity: legal_entities[0], ownership_percentage: 51, relationship_types: ["beneficial_owner"] },
  { parent_legal_entity: legal_entities[5], child_legal_entity: legal_entities[1], ownership_percentage: 30, relationship_types: ["beneficial_owner"] },
  { parent_legal_entity: legal_entities[6], child_legal_entity: legal_entities[2], relationship_types: ["control_person"] },
].each do |attrs|
  LegalEntityRelationship.find_or_create_by!(parent_legal_entity: attrs[:parent_legal_entity], child_legal_entity: attrs[:child_legal_entity]) do |r|
    r.assign_attributes(attrs.merge(public_id: SecureRandom.uuid))
  end
end
puts "  ✓ LegalEntityRelationships: #{LegalEntityRelationship.count}"

# ---------------------------------------------------------------------------
# 8. Bank Legal Entities (2)
# ---------------------------------------------------------------------------
BankLegalEntity.find_or_create_by!(legal_entity: legal_entities[4], entity: "cross_river") { |b| b.status = "completed" }
BankLegalEntity.find_or_create_by!(legal_entity: legal_entities[5], entity: "paxos") { |b| b.status = "completed" }
puts "  ✓ BankLegalEntities: #{BankLegalEntity.count}"

# ---------------------------------------------------------------------------
# 9. Accounts (6)
# ---------------------------------------------------------------------------
accounts = [
  { party_name: "Meridian Operating", legal_entity: legal_entities[4], party_address: addresses[0], currency: "USD", status: "active", active_at: 6.months.ago },
  { party_name: "Meridian Settlement", legal_entity: legal_entities[4], party_address: addresses[0], currency: "USD", status: "active", active_at: 6.months.ago },
  { party_name: "Atlas GBP Account", legal_entity: legal_entities[5], party_address: addresses[3], currency: "GBP", status: "active", active_at: 3.months.ago },
  { party_name: "Atlas USD Account", legal_entity: legal_entities[5], party_address: addresses[0], currency: "USD", status: "active", active_at: 3.months.ago },
  { party_name: "Beacon Crypto Custody", legal_entity: legal_entities[6], party_address: addresses[1], currency: "USD", status: "pending_activation" },
  { party_name: "Elena Personal", legal_entity: legal_entities[0], party_address: addresses[0], currency: "USD", status: "active", active_at: 1.year.ago },
].map { |attrs| Account.find_or_create_by!(party_name: attrs[:party_name]) { |a| a.assign_attributes(attrs.merge(public_id: SecureRandom.uuid)) } }

puts "  ✓ Accounts: #{Account.count}"

# ---------------------------------------------------------------------------
# 10. Account Balances (6)
# ---------------------------------------------------------------------------
[
  { account: accounts[0], available_amount: 1_250_000_00, posted_amount: 1_300_000_00, pending_amount: 50_000_00 },
  { account: accounts[1], available_amount: 500_000_00, posted_amount: 500_000_00, pending_amount: 0 },
  { account: accounts[2], available_amount: 750_000_00, posted_amount: 780_000_00, pending_amount: 30_000_00 },
  { account: accounts[3], available_amount: 2_100_000_00, posted_amount: 2_100_000_00, pending_amount: 0 },
  { account: accounts[4], available_amount: 3_400_000_00, posted_amount: 3_500_000_00, pending_amount: 100_000_00 },
  { account: accounts[5], available_amount: 45_000_00, posted_amount: 45_000_00, pending_amount: 0 },
].each { |attrs| AccountBalance.find_or_create_by!(account: attrs[:account]) { |ab| ab.assign_attributes(attrs) } }

puts "  ✓ AccountBalances: #{AccountBalance.count}"

# ---------------------------------------------------------------------------
# 11. Settlement Accounts (3)
# ---------------------------------------------------------------------------
settlement_accounts = [
  SettlementAccount.find_or_create_by!(account: accounts[1], entity: "cross_river") { |s| s.status = "active" },
  SettlementAccount.find_or_create_by!(account: accounts[3], entity: "cross_river") { |s| s.status = "active" },
  SettlementAccount.find_or_create_by!(account: accounts[4], entity: "paxos") { |s| s.status = "pending" },
]
puts "  ✓ SettlementAccounts: #{SettlementAccount.count}"

# ---------------------------------------------------------------------------
# 12. Program Limits (2)
# ---------------------------------------------------------------------------
program_limits = [
  ProgramLimit.find_or_create_by!(program: standard_program, payment_type: "ach", currency: "USD") { |pl| pl.assign_attributes(limit: 10_000_000_00, direction: "credit", public_id: SecureRandom.uuid) },
  ProgramLimit.find_or_create_by!(program: crypto_program, payment_type: "rtp", currency: "USD") { |pl| pl.assign_attributes(limit: 50_000_000_00, direction: "credit", public_id: SecureRandom.uuid) },
]
puts "  ✓ ProgramLimits: #{ProgramLimit.count}"

# ---------------------------------------------------------------------------
# 13. Account Capabilities (4)
# ---------------------------------------------------------------------------
acct_caps = [
  AccountCapability.find_or_create_by!(account: accounts[0], bank_capability: ach_cap) { |ac| ac.assign_attributes(settlement_account: settlement_accounts[0], program_limit: program_limits[0], public_id: SecureRandom.uuid) },
  AccountCapability.find_or_create_by!(account: accounts[0], bank_capability: wire_cap) { |ac| ac.assign_attributes(settlement_account: settlement_accounts[0], program_limit: program_limits[0], public_id: SecureRandom.uuid) },
  AccountCapability.find_or_create_by!(account: accounts[3], bank_capability: ach_cap) { |ac| ac.assign_attributes(settlement_account: settlement_accounts[1], program_limit: program_limits[0], public_id: SecureRandom.uuid) },
  AccountCapability.find_or_create_by!(account: accounts[4], bank_capability: rtp_cap) { |ac| ac.assign_attributes(settlement_account: settlement_accounts[2], program_limit: program_limits[1], public_id: SecureRandom.uuid) },
]
puts "  ✓ AccountCapabilities: #{AccountCapability.count}"

# ---------------------------------------------------------------------------
# 14. Program Entitlements (2)
# ---------------------------------------------------------------------------
ProgramEntitlement.find_or_create_by!(bank_capability: ach_cap, program_limit: program_limits[0]) { |pe| pe.public_id = SecureRandom.uuid }
ProgramEntitlement.find_or_create_by!(bank_capability: rtp_cap, program_limit: program_limits[1]) { |pe| pe.public_id = SecureRandom.uuid }
puts "  ✓ ProgramEntitlements: #{ProgramEntitlement.count}"

# ---------------------------------------------------------------------------
# 15. Transfers (10)
# ---------------------------------------------------------------------------
transfers = [
  { account: accounts[0], account_capability: acct_caps[0], amount: 25_000_00, currency: "USD", payment_type: "ach", direction: "credit", status: "completed", transfer_type: "payment", account_role: "originating", completed_at: 5.days.ago },
  { account: accounts[0], account_capability: acct_caps[0], amount: 150_000_00, currency: "USD", payment_type: "ach", direction: "credit", status: "completed", transfer_type: "payment", account_role: "originating", completed_at: 3.days.ago },
  { account: accounts[0], account_capability: acct_caps[1], amount: 500_000_00, currency: "USD", payment_type: "wire", direction: "credit", status: "completed", transfer_type: "payment", account_role: "originating", completed_at: 1.day.ago },
  { account: accounts[0], account_capability: acct_caps[0], amount: 10_000_00, currency: "USD", payment_type: "ach", direction: "debit", status: "completed", transfer_type: "payment", account_role: "receiving", completed_at: 2.days.ago },
  { account: accounts[3], account_capability: acct_caps[2], amount: 75_000_00, currency: "USD", payment_type: "ach", direction: "credit", status: "pending", transfer_type: "payment", account_role: "originating", pending_at: 1.hour.ago },
  { account: accounts[3], account_capability: acct_caps[2], amount: 200_000_00, currency: "USD", payment_type: "ach", direction: "credit", status: "processing", transfer_type: "payment", account_role: "originating", processing_at: 30.minutes.ago },
  { account: accounts[4], account_capability: acct_caps[3], amount: 1_000_000_00, currency: "USD", payment_type: "rtp", direction: "credit", status: "completed", transfer_type: "payment", account_role: "originating", completed_at: 12.hours.ago },
  { account: accounts[4], account_capability: acct_caps[3], amount: 50_000_00, currency: "USD", payment_type: "rtp", direction: "debit", status: "failed", transfer_type: "payment", account_role: "receiving", failed_at: 6.hours.ago, failure_reason: "insufficient_funds" },
  { account: accounts[0], account_capability: acct_caps[0], amount: 5_000_00, currency: "USD", payment_type: "ach", direction: "credit", status: "returned", transfer_type: "payment", account_role: "originating", returned_at: 4.days.ago },
  { account: accounts[5], account_capability: acct_caps[0], amount: 2_500_00, currency: "USD", payment_type: "ach", direction: "debit", status: "completed", transfer_type: "payment", account_role: "receiving", completed_at: 1.day.ago },
].map.with_index { |attrs, i| Transfer.create!(attrs.merge(public_id: SecureRandom.uuid, external_id: "xfer_#{i + 1}_#{SecureRandom.hex(4)}")) }

puts "  ✓ Transfers: #{Transfer.count}"

# ---------------------------------------------------------------------------
# 16. Transfer References (3)
# ---------------------------------------------------------------------------
TransferReference.find_or_create_by!(transfer: transfers[0], reference_type: "ach_trace_number") { |tr| tr.assign_attributes(reference_value: "091000019123456", public_id: SecureRandom.uuid) }
TransferReference.find_or_create_by!(transfer: transfers[2], reference_type: "fedwire_imad") { |tr| tr.assign_attributes(reference_value: "20260315MMQFMP080001", public_id: SecureRandom.uuid) }
TransferReference.find_or_create_by!(transfer: transfers[6], reference_type: "ach_trace_number") { |tr| tr.assign_attributes(reference_value: "091000019789012", public_id: SecureRandom.uuid) }
puts "  ✓ TransferReferences: #{TransferReference.count}"

# ---------------------------------------------------------------------------
# 17. Transfer Seasonings (2)
# ---------------------------------------------------------------------------
Transfer::Seasoning.find_or_create_by!(transfer: transfers[0]) { |ts| ts.status = "completed"; ts.end_at = 2.days.ago }
Transfer::Seasoning.find_or_create_by!(transfer: transfers[2]) { |ts| ts.status = "pending" }
puts "  ✓ Transfer::Seasonings: #{Transfer::Seasoning.count}"

# ---------------------------------------------------------------------------
# 18. Books (2)
# ---------------------------------------------------------------------------
Book.find_or_create_by!(originating_transfer: transfers[0]) { |b| b.assign_attributes(receiving_transfer: transfers[3], public_id: SecureRandom.uuid) }
Book.find_or_create_by!(originating_transfer: transfers[4]) { |b| b.assign_attributes(receiving_transfer: transfers[5], public_id: SecureRandom.uuid) }
puts "  ✓ Books: #{Book.count}"

# ---------------------------------------------------------------------------
# 19. Returns (1)
# ---------------------------------------------------------------------------
Return.find_or_create_by!(original_transfer: transfers[8]) { |r| r.assign_attributes(code: "R01", reason: "Insufficient funds", public_id: SecureRandom.uuid) }
puts "  ✓ Returns: #{Return.count}"

# ---------------------------------------------------------------------------
# 20. ACH NOCs (1)
# ---------------------------------------------------------------------------
AchNoc.find_or_create_by!(transfer: transfers[3]) { |n| n.assign_attributes(code: "C01", corrected_routing_number: "021000089", public_id: SecureRandom.uuid) }
puts "  ✓ AchNocs: #{AchNoc.count}"

# ---------------------------------------------------------------------------
# 21. Verifications (4 - STI mix)
# ---------------------------------------------------------------------------
Verification.find_or_create_by!(transfer: transfers[0], type: nil) { |v| v.assign_attributes(status: "passed", data: { check: "ofac", result: "clear" }) }
Verification::Route.find_or_create_by!(transfer: transfers[2]) { |v| v.assign_attributes(status: "passed", data: { route: "fedwire", validated: true }) }
Verification::Sardine.find_or_create_by!(transfer: transfers[6]) { |v| v.assign_attributes(status: "passed", data: { risk_score: 12, signals: [] }) }
Verification::Settlement.find_or_create_by!(transfer: transfers[4]) { |v| v.assign_attributes(status: "processing", data: { settlement_date: Date.tomorrow.to_s }) }
puts "  ✓ Verifications: #{Verification.count}"

# ---------------------------------------------------------------------------
# 22. Decisions (3)
# ---------------------------------------------------------------------------
decisions = [
  Decision.find_or_create_by!(legal_entity: legal_entities[0]) { |d| d.assign_attributes(status: "passed", details: { type: "kyc_onboarding" }) },
  Decision.find_or_create_by!(legal_entity: legal_entities[4]) { |d| d.assign_attributes(status: "passed", details: { type: "kyb_onboarding" }) },
  Decision.find_or_create_by!(legal_entity: legal_entities[6]) { |d| d.assign_attributes(status: "needs_review", details: { type: "periodic_review" }) },
]
puts "  ✓ Decisions: #{Decision.count}"

# ---------------------------------------------------------------------------
# 23. Evaluations (4)
# ---------------------------------------------------------------------------
Evaluation.find_or_create_by!(decision: decisions[0], legal_entity: legal_entities[0], vendor_id: "eval_kyc_001") { |e| e.assign_attributes(status: "passed", details: { check: "kyc" }) }
Evaluation.find_or_create_by!(decision: decisions[0], legal_entity: legal_entities[0], vendor_id: "eval_sanctions_001") { |e| e.assign_attributes(status: "passed", details: { check: "sanctions_screening" }) }
Evaluation.find_or_create_by!(decision: decisions[1], legal_entity: legal_entities[4], vendor_id: "eval_kyb_001") { |e| e.assign_attributes(status: "passed", details: { check: "kyb" }) }
Evaluation.find_or_create_by!(decision: decisions[2], legal_entity: legal_entities[6], vendor_id: "eval_review_001") { |e| e.assign_attributes(status: "needs_review", details: { check: "periodic_review", risk_factors: ["high_volume", "new_geography"] }) }
puts "  ✓ Evaluations: #{Evaluation.count}"

# ---------------------------------------------------------------------------
# 24. Documents (2 - polymorphic)
# ---------------------------------------------------------------------------
Document.find_or_create_by!(documentable: individuals[0], document_type: "passport") { |d| d.public_id = SecureRandom.uuid }
Document.find_or_create_by!(documentable: businesses[0], document_type: "articles_of_incorporation") { |d| d.public_id = SecureRandom.uuid }
puts "  ✓ Documents: #{Document.count}"

# ---------------------------------------------------------------------------
# 25. Identifications (3 - polymorphic)
# ---------------------------------------------------------------------------
Identification.find_or_create_by!(identifiable: individuals[0], id_type: "passport") { |i| i.assign_attributes(id_number_ciphertext: "encrypted_X12345678", issuing_country: "US", public_id: SecureRandom.uuid) }
Identification.find_or_create_by!(identifiable: individuals[1], id_type: "drivers_license") { |i| i.assign_attributes(id_number_ciphertext: "encrypted_D9876543", issuing_country: "US", public_id: SecureRandom.uuid) }
Identification.find_or_create_by!(identifiable: businesses[0], id_type: "ein") { |i| i.assign_attributes(id_number_ciphertext: "encrypted_123456789", issuing_country: "US", public_id: SecureRandom.uuid) }
puts "  ✓ Identifications: #{Identification.count}"

# ---------------------------------------------------------------------------
# 26. Turbogrid (1 scope + 1 state)
# ---------------------------------------------------------------------------
scope = Turbogrid::SearchScope.find_or_create_by!(namespace: "transfers", resource: "Transfer") { |s| s.columns = { visible: %w[id status amount currency direction] } }
Turbogrid::GridState.find_or_create_by!(search_scope: scope) { |g| g.data = { sort: { field: "created_at", direction: "desc" } } }
puts "  ✓ Turbogrid: #{Turbogrid::SearchScope.count} scopes, #{Turbogrid::GridState.count} states"

# ---------------------------------------------------------------------------
# DEMO — Corner Coffee LLC (hero case: $45k wire, HIGH risk, SLA BREACHED)
# ---------------------------------------------------------------------------

corner_coffee_biz = Business.find_or_create_by!(business_name: "Corner Coffee LLC") do |b|
  b.public_id               = SecureRandom.uuid
  b.primary_email           = "ops@cornercoffee.example.com"
  b.primary_phone           = "+12125559001"
  b.country_of_incorporation = "US"
  b.legal_structure         = "llc"
  b.industry                = "food_beverage"
  b.source_of_funds         = "retail_sales"
  b.naics_code              = "722515"
  b.physical_address        = addresses[4]
  b.primary_address         = addresses[4]
end

corner_coffee_le = LegalEntity.find_or_create_by!(entity: corner_coffee_biz) do |l|
  l.public_id    = SecureRandom.uuid
  l.program      = standard_program
  l.status       = "active"
  l.role         = "standard"
  l.risk_rating  = "high"
  l.external_id  = "ext_corner_coffee_001"
  l.active_at    = 4.months.ago
end

# C2 under Meridian Fintech (legal_entities[4])
LegalEntityRelationship.find_or_create_by!(
  parent_legal_entity: legal_entities[4],
  child_legal_entity:  corner_coffee_le
) do |r|
  r.public_id          = SecureRandom.uuid
  r.relationship_types = ["beneficial_owner"]
  r.ownership_percentage = 100
end

corner_coffee_account = Account.find_or_create_by!(party_name: "Corner Coffee Operating") do |a|
  a.public_id      = SecureRandom.uuid
  a.legal_entity   = corner_coffee_le
  a.party_address  = addresses[4]
  a.currency       = "USD"
  a.status         = "active"
  a.active_at      = 4.months.ago
end

AccountBalance.find_or_create_by!(account: corner_coffee_account) do |ab|
  ab.available_amount = 12_500_00
  ab.posted_amount    = 12_500_00
  ab.pending_amount   = 45_000_00
end

corner_coffee_decision = Decision.find_or_create_by!(legal_entity: corner_coffee_le, vendor_id: "inq_corner_kyb_001") do |d|
  d.status     = "passed"
  d.expires_at = 8.months.from_now
  d.details    = { type: "kyb_onboarding", completed_at: 4.months.ago.iso8601 }
end

Evaluation.find_or_create_by!(decision: corner_coffee_decision, legal_entity: corner_coffee_le, vendor_id: "eval_corner_biz_001") do |e|
  e.status  = "passed"
  e.details = { check: "business_verification", result: "verified" }
end
Evaluation.find_or_create_by!(decision: corner_coffee_decision, legal_entity: corner_coffee_le, vendor_id: "eval_corner_sanctions_001") do |e|
  e.status  = "passed"
  e.details = { check: "sanctions_screening", result: "clear" }
end

# 90-day wire history (for Compliance full TX view)
[
  { amount: 12_000_00, completed_at: 45.days.ago },
  { amount: 18_500_00, completed_at: 22.days.ago },
  { amount: 32_000_00, completed_at: 7.days.ago  },
].each_with_index do |attrs, i|
  Transfer.find_or_create_by!(external_id: "xfer_cc_hist_#{i + 1}") do |t|
    t.public_id     = SecureRandom.uuid
    t.account       = corner_coffee_account
    t.amount        = attrs[:amount]
    t.currency      = "USD"
    t.payment_type  = "wire"
    t.direction     = "credit"
    t.status        = "completed"
    t.transfer_type = "payment"
    t.account_role  = "originating"
    t.completed_at  = attrs[:completed_at]
  end
end

# THE hero held transfer — $45,000 wire, SLA breached (8.5h)
cc_held = Transfer.find_or_create_by!(external_id: "xfer_cc_hero_held") do |t|
  t.public_id     = SecureRandom.uuid
  t.account       = corner_coffee_account
  t.amount        = 45_000_00
  t.currency      = "USD"
  t.payment_type  = "wire"
  t.direction     = "credit"
  t.status        = "held"
  t.held_at       = 8.5.hours.ago
  t.transfer_type = "payment"
  t.account_role  = "originating"
end

Verification::Sardine.find_or_create_by!(transfer: cc_held) do |v|
  v.status           = "held"
  v.vendor_id        = "sardine_case_cc_001"
  v.rejection_reason = "wire_layering_pattern"
  v.data = {
    risk_score: 87,
    reason:     "wire_layering_pattern",
    alert_type: "WIRE_PATTERN",
    contributing_factors: [
      { code: "HIGH_VELOCITY",      description: "3 wire transfers over $10k in 45 days" },
      { code: "UNUSUAL_AMOUNT",     description: "Transfer 40% above 90-day average" },
      { code: "NEW_COUNTERPARTY",   description: "Beneficiary account first seen 12 days ago" }
    ],
    signals:  %w[high_velocity_wire unusual_counterparty amount_spike],
    case_id:  "case_sardine_cc_001"
  }
end

puts "  ✓ Corner Coffee LLC: hero scenario seeded (held: $45k wire, risk_score: 87)"

# ---------------------------------------------------------------------------
# DEMO — Fresh Beans Co (onboarding: KYB needs_review, UBO docs missing)
# ---------------------------------------------------------------------------

fresh_beans_addr = Address.find_or_create_by!(line1: "512 South Congress Ave", locality: "Austin") do |a|
  a.region      = "TX"
  a.postal_code = "78704"
  a.country_code = "US"
end

fresh_beans_biz = Business.find_or_create_by!(business_name: "Fresh Beans Co") do |b|
  b.public_id                = SecureRandom.uuid
  b.primary_email            = "hello@freshbeans.example.com"
  b.primary_phone            = "+15125559002"
  b.country_of_incorporation = "US"
  b.legal_structure          = "llc"
  b.industry                 = "food_beverage"
  b.source_of_funds          = "retail_sales"
  b.naics_code               = "722515"
  b.physical_address         = fresh_beans_addr
  b.primary_address          = fresh_beans_addr
end

fresh_beans_le = LegalEntity.find_or_create_by!(entity: fresh_beans_biz) do |l|
  l.public_id   = SecureRandom.uuid
  l.program     = standard_program
  l.status      = "pending"
  l.role        = "standard"
  l.risk_rating = "medium"
  l.external_id = "ext_fresh_beans_001"
  l.pending_at  = 4.days.ago
end

fresh_beans_decision = Decision.find_or_create_by!(legal_entity: fresh_beans_le, vendor_id: "inq_fresh_beans_kyb_001") do |d|
  d.status  = "needs_review"
  d.details = { type: "kyb_onboarding", started_at: 4.days.ago.iso8601 }
end

Evaluation.find_or_create_by!(decision: fresh_beans_decision, legal_entity: fresh_beans_le, vendor_id: "eval_fb_biz_001") do |e|
  e.status  = "passed"
  e.details = { check: "business_verification", result: "verified" }
end
Evaluation.find_or_create_by!(decision: fresh_beans_decision, legal_entity: fresh_beans_le, vendor_id: "eval_fb_sanctions_001") do |e|
  e.status  = "passed"
  e.details = { check: "sanctions_screening", result: "clear" }
end
Evaluation.find_or_create_by!(decision: fresh_beans_decision, legal_entity: fresh_beans_le, vendor_id: "eval_fb_ubo_001") do |e|
  e.status  = "needs_review"
  e.details = {
    check:          "ubo_documentation",
    result:         "incomplete",
    ubo_count:      2,
    ubo_verified:   false,
    docs_collected: %w[certificate_of_incorporation ein_letter],
    docs_missing:   %w[ubo_passport proof_of_address]
  }
end

puts "  ✓ Fresh Beans Co: onboarding scenario seeded (UBO docs missing)"

# ---------------------------------------------------------------------------
# ONBOARDING QUEUE — 3 more pending entities
# ---------------------------------------------------------------------------

[
  { name: "Sunrise Bakery LLC",        email: "admin@sunrisebakery.example.com",  risk: "low",    external: "ext_sunrise_001",    days_ago: 1 },
  { name: "Tidal Wave Imports Inc",    email: "finance@tidalwave.example.com",    risk: "high",   external: "ext_tidal_001",      days_ago: 3 },
  { name: "Green Path Consulting LLC", email: "ops@greenpath.example.com",        risk: "medium", external: "ext_greenpath_001",  days_ago: 7 },
].each do |attrs|
  biz = Business.find_or_create_by!(business_name: attrs[:name]) do |b|
    b.public_id                = SecureRandom.uuid
    b.primary_email            = attrs[:email]
    b.country_of_incorporation = "US"
    b.legal_structure          = "llc"
    b.physical_address         = addresses[4]
    b.primary_address          = addresses[4]
  end
  le = LegalEntity.find_or_create_by!(entity: biz) do |l|
    l.public_id   = SecureRandom.uuid
    l.program     = standard_program
    l.status      = "pending"
    l.role        = "standard"
    l.risk_rating = attrs[:risk]
    l.external_id = attrs[:external]
    l.pending_at  = attrs[:days_ago].days.ago
  end
  Decision.find_or_create_by!(legal_entity: le, vendor_id: "inq_#{attrs[:external]}_kyb") do |d|
    d.status  = "running"
    d.details = { type: "kyb_onboarding" }
  end
end

puts "  ✓ Onboarding queue: 3 more entities seeded"

# ---------------------------------------------------------------------------
# HELD PAYMENT QUEUE — 3 more transfers (varying SLA)
# ---------------------------------------------------------------------------

[
  # ok SLA (1.5h) — Meridian account
  { account: accounts[0], ext_id: "xfer_held_queue_1", amount: 8_750_00,  payment_type: "ach",  held_hours: 1.5, risk_score: 38, reason: "unusual_frequency" },
  # warning SLA (4h) — Atlas account
  { account: accounts[3], ext_id: "xfer_held_queue_2", amount: 28_500_00, payment_type: "wire", held_hours: 4.0, risk_score: 62, reason: "geo_mismatch" },
  # breached SLA (12h) — Corner Coffee 2nd hold
  { account: corner_coffee_account, ext_id: "xfer_held_queue_3", amount: 15_000_00, payment_type: "wire", held_hours: 12.0, risk_score: 78, reason: "new_counterparty" },
].each do |ht|
  t = Transfer.find_or_create_by!(external_id: ht[:ext_id]) do |t|
    t.public_id     = SecureRandom.uuid
    t.account       = ht[:account]
    t.amount        = ht[:amount]
    t.currency      = "USD"
    t.payment_type  = ht[:payment_type]
    t.direction     = "credit"
    t.status        = "held"
    t.held_at       = ht[:held_hours].hours.ago
    t.transfer_type = "payment"
    t.account_role  = "originating"
  end
  Verification::Sardine.find_or_create_by!(transfer: t) do |v|
    v.status           = "held"
    v.vendor_id        = "sardine_#{ht[:ext_id]}"
    v.rejection_reason = ht[:reason]
    v.data             = { risk_score: ht[:risk_score], reason: ht[:reason], signals: [ht[:reason]], contributing_factors: [] }
  end
end

puts "  ✓ Held queue: #{Transfer.where(status: 'held').count} total held transfers"

# ---------------------------------------------------------------------------
load Rails.root.join("db/seeds/bulk.rb")

puts "\n========================================="
puts " Seed complete! Record counts:"
puts "========================================="
[Address, Program, BankCapability, Individual, Business, LegalEntity,
 LegalEntityRelationship, BankLegalEntity, Account, AccountBalance,
 SettlementAccount, ProgramLimit, AccountCapability, ProgramEntitlement,
 Transfer, TransferReference, Transfer::Seasoning, Book, Return, AchNoc,
 Verification, Decision, Evaluation, Document, Identification].each do |klass|
  puts " #{klass.name.ljust(30)} #{klass.count}"
end
puts "========================================="
