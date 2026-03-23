# frozen_string_literal: true
# Bulk data seed — generates 150+ records per major entity (10+ pages in FA).
# Idempotent: guarded by external_id prefixes; safe to run multiple times.

puts "\nSeeding bulk data..."

# ── Guard — skip if already seeded ───────────────────────────────────────────
if LegalEntity.where("external_id LIKE 'bulk_%'").count >= 100
  puts "  ✓ Bulk data already present — skipping"
  return
end

# ── Reference data ────────────────────────────────────────────────────────────
standard_program = Program.find_by!(name: "Standard Payments")
crypto_program   = Program.find_by!(name: "Crypto Operations")
programs         = [standard_program, crypto_program]
addresses        = Address.all.to_a

# ── Name pools ────────────────────────────────────────────────────────────────
PREFIXES = %w[
  Apex Atlas Beacon Bridge Cascade Cedar Crest Delta Echo Ember Frontier Galaxy
  Harbor Horizon Iris Jade Keystone Latitude Mesa Nova Orbit Peak Prism Quantum
  Ridge Summit Terra Tide Unity Vega Vertex Wave Zenith Acme Allied Alpine Anchor
  Arc Arrow Aurora Bolt Bright Capital Coral Crown Crystal Dawn Dune Edge Falcon
  Forge Haven Highland Indigo Iron Lark Lime Lunar Lynx Maple Metro Mill Mint
  Mosaic Noble Oak Pacific Palm Pine Polar Port Rapid Raven River Rock Rose Ruby
  Rush Silver Sky Slate Solar Sonic Star Steel Storm Swift Teal Titan Torch Tower
  Trek True Ultra Urban Vale Valor Vapor Vast View Vision Volt Wood Yard Zeal
].freeze

SUFFIXES = %w[
  Financial Technologies Solutions Partners Group Holdings Capital Ventures Labs
  Systems Global Digital Commerce Services Payments Logistics Analytics Consulting
  Management Corp LLC Inc Ltd
].freeze

INDUSTRIES   = %w[fintech ecommerce logistics healthcare retail manufacturing consulting real_estate food_beverage media].freeze
NAICS_CODES  = %w[522110 522210 454110 492110 621111 441110 722515 531210 511210 519130].freeze
RISK_WEIGHTS = (%w[low] * 5 + %w[medium] * 3 + %w[high] * 2).freeze
STATUS_WEIGHTS_ACTIVE  = (%w[active] * 7 + %w[pending] * 2 + %w[suspended] * 1).freeze
PAYMENT_TYPES  = %w[ach ach ach wire wire rtp].freeze
XFER_STATUSES  = (%w[completed] * 8 + %w[pending processing held failed returned] * 1).freeze
SARDINE_REASONS = %w[
  geo_mismatch wire_layering_pattern unusual_frequency new_counterparty
  high_velocity amount_spike structured_transactions velocity_breach
].freeze
DECISION_STATUSES = (%w[passed] * 6 + %w[needs_review failed running expired] * 1).freeze
EVAL_CHECKS = %w[business_verification sanctions_screening ubo_documentation
                 proof_of_address source_of_funds adverse_media pep_screening].freeze

FIRST_NAMES = %w[Alex Jordan Morgan Casey Riley Quinn Avery Drew Blake Cameron Dana
                 Elliot Finley Harper Hayden Indira Kai Lee Logan Mia Noah].freeze
LAST_NAMES  = %w[Anderson Baker Campbell Davis Evans Foster Garcia Harris Jackson
                 Johnson Kim Lee Martinez Nelson Nguyen Park Roberts Singh Thompson].freeze

def bulk_email(i) = "bulk_contact_#{i}@demo.example.com"
def bulk_amount   = [rand(5_000..99_999), rand(100_000..999_999), rand(1_000_000..5_000_000)].sample

# ── C1 Legal Entities (40) ───────────────────────────────────────────────────
puts "  Generating C1 entities..."
c1_les = []

40.times do |i|
  name = "#{PREFIXES[i % PREFIXES.length]} #{SUFFIXES.sample} #{i}"
  biz  = Business.find_or_create_by!(business_name: name) do |b|
    b.public_id                 = SecureRandom.uuid
    b.primary_email             = bulk_email("c1_#{i}")
    b.country_of_incorporation  = %w[US US US GB CA].sample
    b.legal_structure           = %w[llc corporation].sample
    b.industry                  = INDUSTRIES.sample
    b.naics_code                = NAICS_CODES.sample
    b.physical_address          = addresses.sample
    b.primary_address           = addresses.sample
  end

  le = LegalEntity.find_or_create_by!(entity_type: "Business", entity_id: biz.id) do |l|
    l.public_id   = SecureRandom.uuid
    l.program     = programs.sample
    l.status      = %w[active active active suspended].sample
    l.role        = "standard"
    l.risk_rating = RISK_WEIGHTS.sample
    l.external_id = "bulk_c1_#{i.to_s.rjust(3, '0')}"
    l.active_at   = rand(6..36).months.ago
  end
  c1_les << le
end
puts "  ✓ C1 entities: #{c1_les.length}"

# ── C2 Legal Entities (120) ──────────────────────────────────────────────────
puts "  Generating C2 entities..."
c2_les = []
c1_pool = c1_les + LegalEntity.where("external_id LIKE 'ext_c1_%'").to_a

120.times do |i|
  name = "#{PREFIXES.sample} #{PREFIXES.sample} #{SUFFIXES.sample} #{i}"
  biz  = Business.find_or_create_by!(business_name: name) do |b|
    b.public_id                = SecureRandom.uuid
    b.primary_email            = bulk_email("c2_#{i}")
    b.country_of_incorporation = %w[US US US GB CA SG].sample
    b.legal_structure          = %w[llc corporation sole_proprietorship].sample
    b.industry                 = INDUSTRIES.sample
    b.naics_code               = NAICS_CODES.sample
    b.physical_address         = addresses.sample
    b.primary_address          = addresses.sample
  end

  status = STATUS_WEIGHTS_ACTIVE.sample
  le = LegalEntity.find_or_create_by!(entity_type: "Business", entity_id: biz.id) do |l|
    l.public_id   = SecureRandom.uuid
    l.program     = programs.sample
    l.status      = status
    l.role        = "standard"
    l.risk_rating = RISK_WEIGHTS.sample
    l.external_id = "bulk_c2_#{i.to_s.rjust(3, '0')}"
    l.active_at   = status == "active"  ? rand(1..24).months.ago : nil
    l.pending_at  = status == "pending" ? rand(1..30).days.ago   : nil
  end

  parent = c1_pool.sample
  LegalEntityRelationship.find_or_create_by!(parent_legal_entity: parent, child_legal_entity: le) do |r|
    r.public_id            = SecureRandom.uuid
    r.relationship_types   = [%w[beneficial_owner subsidiary control_person].sample]
    r.ownership_percentage = [25, 51, 75, 100].sample
  end

  c2_les << le
end
puts "  ✓ C2 entities: #{c2_les.length}"

# ── Individual Legal Entities (20) ───────────────────────────────────────────
puts "  Generating individual entities..."
20.times do |i|
  fname = FIRST_NAMES[i % FIRST_NAMES.length]
  lname = LAST_NAMES[i % LAST_NAMES.length]
  email = "#{fname.downcase}.#{lname.downcase}.bulk#{i}@example.com"

  ind = Individual.find_or_create_by!(primary_email: email) do |ind|
    ind.public_id               = SecureRandom.uuid
    ind.first_name              = fname
    ind.last_name               = lname
    ind.primary_phone           = "+1#{rand(200..999)}#{rand(100..999)}#{rand(1000..9999)}"
    ind.date_of_birth           = Date.new(rand(1960..2000), rand(1..12), rand(1..28))
    ind.citizenship_country_code = %w[US US GB CA].sample
    ind.primary_address         = addresses.sample
  end

  LegalEntity.find_or_create_by!(entity_type: "Individual", entity_id: ind.id) do |l|
    l.public_id   = SecureRandom.uuid
    l.program     = standard_program
    l.status      = %w[active active pending].sample
    l.role        = "standard"
    l.risk_rating = %w[low low medium].sample
    l.external_id = "bulk_ind_#{i.to_s.rjust(3, '0')}"
    l.active_at   = rand(1..18).months.ago
  end
end
puts "  ✓ Individual entities generated"

# ── Accounts + Balances ───────────────────────────────────────────────────────
puts "  Generating accounts..."
bulk_les  = c1_les + c2_les
new_accts = []

bulk_les.each do |le|
  next if Account.exists?(legal_entity: le)

  entity_name = Business.find_by(id: le.entity_id)&.business_name || "Entity #{le.id}"
  n = c1_les.include?(le) ? rand(1..2) : 1

  n.times do |j|
    suffix = j == 0 ? "Operating" : %w[Settlement Reserve].sample
    acct = Account.create!(
      public_id:    SecureRandom.uuid,
      legal_entity: le,
      party_name:   "#{entity_name} #{suffix}",
      party_address: addresses.sample,
      currency:     %w[USD USD USD GBP EUR].sample,
      status:       le.status == "active" ? "active" : (le.status == "pending" ? "pending_activation" : "suspended"),
      active_at:    le.status == "active" ? rand(1..18).months.ago : nil
    )
    AccountBalance.create!(
      account:          acct,
      available_amount: rand(0..5_000_000) * 100,
      posted_amount:    rand(0..5_000_000) * 100,
      pending_amount:   rand(0..500_000)   * 100
    )
    new_accts << acct
  end
end
puts "  ✓ Accounts: #{new_accts.length} new"

# ── Transfers ─────────────────────────────────────────────────────────────────
puts "  Generating transfers (may take a moment)..."
active_accts    = new_accts.select { |a| a.status == "active" }
new_held        = []
transfer_count  = 0

active_accts.each do |acct|
  rand(3..5).times do
    status   = XFER_STATUSES.sample
    held_at  = status == "held" ? rand(1..16).hours.ago : nil

    t = Transfer.create!(
      public_id:     SecureRandom.uuid,
      external_id:   "xfer_bulk_#{SecureRandom.hex(6)}",
      account:       acct,
      amount:        bulk_amount,
      currency:      acct.currency,
      payment_type:  PAYMENT_TYPES.sample,
      direction:     %w[credit debit].sample,
      status:        status,
      transfer_type: "payment",
      account_role:  %w[originating receiving].sample,
      held_at:       held_at,
      completed_at:  status == "completed"  ? rand(1..90).days.ago  : nil,
      failed_at:     status == "failed"     ? rand(1..30).days.ago  : nil,
      pending_at:    status == "pending"    ? rand(1..48).hours.ago : nil,
      processing_at: status == "processing" ? rand(1..12).hours.ago : nil,
      returned_at:   status == "returned"   ? rand(1..14).days.ago  : nil
    )
    new_held       << t if status == "held"
    transfer_count += 1
  end
end
puts "  ✓ Transfers: #{transfer_count} new (#{new_held.length} held)"

# ── Sardine verifications for new held transfers ───────────────────────────────
puts "  Generating Sardine verifications..."
new_held.each do |t|
  reason     = SARDINE_REASONS.sample
  risk_score = rand(40..95)
  Verification::Sardine.create!(
    transfer:         t,
    status:           "held",
    vendor_id:        "sardine_bulk_#{SecureRandom.hex(4)}",
    rejection_reason: reason,
    data:             { risk_score: risk_score, reason: reason, signals: [reason], contributing_factors: [] }
  )
end
puts "  ✓ Sardine verifications: #{new_held.length} new"

# ── Decisions + Evaluations ───────────────────────────────────────────────────
puts "  Generating decisions & evaluations..."
dec_count  = 0
eval_count = 0

bulk_les.each do |le|
  next if Decision.exists?(legal_entity: le)

  status   = DECISION_STATUSES.sample
  expires  = status == "passed" ? rand(3..24).months.from_now : nil
  expires  = rand(1..29).days.from_now if status == "passed" && rand < 0.1 # some expiring soon

  d = Decision.create!(
    legal_entity: le,
    vendor_id:    "inq_bulk_#{SecureRandom.hex(6)}",
    status:       status,
    expires_at:   expires,
    details:      { type: "kyb_onboarding" }
  )
  dec_count += 1

  rand(2..3).times do |j|
    check       = EVAL_CHECKS[j % EVAL_CHECKS.length]
    eval_status = status == "passed" ? "passed" : (j.zero? ? status : %w[passed needs_review].sample)
    Evaluation.create!(
      decision:     d,
      legal_entity: le,
      vendor_id:    "eval_bulk_#{SecureRandom.hex(6)}",
      status:       eval_status,
      details:      { check: check }
    )
    eval_count += 1
  end
end
puts "  ✓ Decisions: #{dec_count} new, Evaluations: #{eval_count} new"

puts "\n  Bulk seed complete:"
puts "  #{LegalEntity.count.to_s.rjust(6)} LegalEntities"
puts "  #{Transfer.count.to_s.rjust(6)} Transfers"
puts "  #{Account.count.to_s.rjust(6)} Accounts"
puts "  #{Decision.count.to_s.rjust(6)} Decisions"
puts "  #{Evaluation.count.to_s.rjust(6)} Evaluations"
puts "  #{Verification.count.to_s.rjust(6)} Verifications"
