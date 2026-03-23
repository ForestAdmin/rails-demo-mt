# Modern Treasury — Forest Admin Demo Spec

## Code Customizations

---

## 1. Context & Objectives

### Who is Modern Treasury

Modern Treasury is a payments infrastructure company transitioning from a pure SaaS model to operating as a Payment Service Provider (PSP). Their core product, **Flow**, is their internal payments and ledger engine — it manages legal entities, transfers, accounts, programs, and limits. Their clients (C1s) use Flow to move money; their clients' clients (C2s/C3s) are the downstream entities that generate transactions and risk signals.

Their stack:

- **Flow** — their own Rails 8.1 app on Aurora Postgres. Source of truth for all payment operations. This is the database Forest Admin connects to via the Ruby agent.
- **Persona** — KYB/KYC provider. Handles identity verification, document collection, UBO verification.
- **Sardine** — sanctions screening and transaction monitoring. Generates risk alerts on transfers and entities.
- **Salesforce** — CRM. Stores C1 account ownership, TAM assignments, customer contacts.
- **MT Risk Engine** — their own internal risk scoring, separate from Sardine.

### What they want

MT is evaluating back office platforms to replace fragmented ops tooling. Today their compliance, ops, and TAM teams work across multiple systems with no unified view. They need:

1. A unified customer and case view across Flow, Persona, Sardine, Salesforce
2. Structured queues for held payments, onboarding, sanctions, and investigations
3. Controlled operational actions (hold/release payments, suspend entities) with approval gates
4. RFI orchestration via Persona one-time-links
5. Full audit trail distinguishing human vs automated actions
6. Low-code workflow configuration — ops should configure without engineering

**POC deadline: March 26, 2026. Demo: Monday March 23.**

### Success metrics they care about

- **Time to First Transaction** — how fast can a new C2 be onboarded and start transacting
- **Held payment resolution time** — average time from Transfer.held to Transfer.processing
- **Manual case rate** — % of transactions requiring human review (they want this to decrease over time)
- **False positive rate** — legitimate transactions blocked by compliance rules

---

## 2. Data Model

### How the schema works

Forest Admin connects to Flow's Aurora Postgres database via the Ruby ActiveRecord agent. All relationships defined in ActiveRecord are automatically detected — no manual declaration needed for intra-datasource relations.

### Key entities

#### `LegalEntity`

The central entity. Represents any customer — C1, C2, or C3 — in Modern Treasury's system.

| Field                              | Type          | Meaning                                    |
| ---------------------------------- | ------------- | ------------------------------------------ |
| `id`                               | Number (PK)   | Internal integer ID                        |
| `public_id`                        | UUID          | External-facing UUID                       |
| `external_id`                      | String        | Customer's own reference                   |
| `entity_type`                      | String        | `business` or `individual`                 |
| `status`                           | Enum          | `active`, `denied`, `pending`, `suspended` |
| `risk_rating`                      | Enum          | `high`, `medium`, `low`                    |
| `role`                             | Enum          | `standard`, `limited`                      |
| `program`                          | BelongsTo     | Which Program this entity is on            |
| `parent`                           | BelongsToMany | Parent LegalEntity (C1 if this is C2)      |
| `children`                         | BelongsToMany | Child LegalEntities                        |
| `child_legal_entity_relationships` | HasMany       | Via LegalEntityRelationship join table     |
| `parent_legal_entity_relationship` | HasOne        | Via LegalEntityRelationship join table     |
| `accounts`                         | HasMany       | Payment accounts                           |
| `decisions`                        | HasMany       | KYB/KYC decisions from Persona             |
| `bank_legal_entities`              | HasMany       | Bank relationships                         |

**C1/C2/C3 hierarchy**: not a field on LegalEntity. Derived from `LegalEntityRelationship`:

- No `parent_legal_entity_relationship` → **C1** (top-level MT client)
- Has a parent → **C2** (client's sub-entity, often source of risk signals)
- Parent is also a C2 → **C3** (downstream entity in complex structures)

#### `Transfer`

The payment object. Every wire, ACH, RTP, book transfer is a Transfer.

| Field                | Type        | Meaning                                                                                             |
| -------------------- | ----------- | --------------------------------------------------------------------------------------------------- |
| `id`                 | Number (PK) | Internal ID                                                                                         |
| `amount`             | Number      | In cents                                                                                            |
| `currency`           | String      | ISO 4217                                                                                            |
| `direction`          | Enum        | `credit`, `debit`                                                                                   |
| `status`             | Enum        | `approved`, `cancelled`, `completed`, `failed`, `held`, `pending`, `processing`, `returned`, `sent` |
| `payment_type`       | Enum        | `ach`, `book`, `card`, `ethereum`, `rtp`, `solana`, `wire`                                          |
| `held_at`            | Date        | When the transfer was put on hold                                                                   |
| `account`            | BelongsTo   | The Account this transfer belongs to                                                                |
| `account_capability` | BelongsTo   | Defines what rail was used                                                                          |
| `verifications`      | HasMany     | All verification results                                                                            |
| `current_seasoning`  | HasOne      | Current seasoning state                                                                             |

`Transfer.status = 'held'` is the trigger for the Held Payments queue. `held_at` is used for SLA calculation.

#### `Verification__Sardine`

Sardine's screening result on a Transfer. Single-table inheritance from `Verification`.

| Field              | Type        | Meaning                                                                  |
| ------------------ | ----------- | ------------------------------------------------------------------------ |
| `id`               | Number (PK) | Internal ID                                                              |
| `transfer`         | BelongsTo   | The Transfer being screened                                              |
| `status`           | Enum        | `held`, `passed`, `processing`, `rejected`                               |
| `type`             | String      | `Verification::Sardine`                                                  |
| `vendor_id`        | String      | Sardine's own alert/case ID                                              |
| `data`             | JSON        | Full Sardine payload: risk score, alert type, contributing factors, etc. |
| `rejection_reason` | String      | Why the transfer was flagged                                             |

`Verification__Sardine.status = 'held'` feeds the Sanctions/Investigations queue. `data` JSON contains the risk score, alert type, and contributing factors shown in the Risk tab.

#### `LegalEntityRelationship`

Join table that defines the C1/C2/C3 hierarchy.

| Field                  | Type          | Meaning                                   |
| ---------------------- | ------------- | ----------------------------------------- |
| `parent_legal_entity`  | BelongsTo     | The C1 (or C2 if this is C3)              |
| `child_legal_entity`   | BelongsTo     | The C2 (or C3)                            |
| `relationship_types`   | Array[String] | e.g. `['beneficial_owner', 'subsidiary']` |
| `ownership_percentage` | Number        | % ownership if applicable                 |
| `title`                | String        | Role of the child in relation to parent   |

#### `Decision`

KYB/KYC decision record, fed by Persona. One Decision per verification event on a LegalEntity.

| Field          | Type      | Meaning                                                  |
| -------------- | --------- | -------------------------------------------------------- |
| `legal_entity` | BelongsTo | Which entity was verified                                |
| `status`       | Enum      | `expired`, `failed`, `needs_review`, `passed`, `running` |
| `vendor_id`    | String    | Persona inquiry ID                                       |
| `details`      | JSON      | Full Persona payload                                     |
| `evaluations`  | HasMany   | Individual check results within this decision            |
| `resolved_by`  | String    | Who resolved a `needs_review` decision                   |
| `expires_at`   | Date      | When this decision expires (KYB periodic review)         |

#### `Evaluation`

Individual check within a Decision (e.g. "UBO verification", "sanctions check", "document collection").

| Field          | Type      | Meaning                                                  |
| -------------- | --------- | -------------------------------------------------------- |
| `decision`     | BelongsTo | Parent Decision                                          |
| `legal_entity` | BelongsTo | The entity                                               |
| `status`       | Enum      | `expired`, `failed`, `needs_review`, `passed`, `running` |
| `vendor_id`    | String    | Persona evaluation ID                                    |
| `details`      | JSON      | Check-specific results                                   |

#### `Account`

A payment account linked to a LegalEntity.

| Field                  | Type      | Meaning                                                                  |
| ---------------------- | --------- | ------------------------------------------------------------------------ |
| `legal_entity`         | BelongsTo | Owner entity                                                             |
| `status`               | Enum      | `active`, `closed`, `pending_activation`, `pending_closure`, `suspended` |
| `currency`             | String    | Account currency                                                         |
| `account_balance`      | HasOne    | Current balance                                                          |
| `transfers`            | HasMany   | All transfers on this account                                            |
| `account_capabilities` | HasMany   | Which rails this account can use                                         |

#### `Business`

Business profile attached to a LegalEntity (when `entity_type = 'business'`).

| Field              | Type      | Meaning                                                                           |
| ------------------ | --------- | --------------------------------------------------------------------------------- |
| `business_name`    | String    | Legal name                                                                        |
| `legal_structure`  | Enum      | `corporation`, `llc`, `non_profit`, `partnership`, `sole_proprietorship`, `trust` |
| `source_of_funds`  | String    | Declared source of funds                                                          |
| `primary_email`    | String    | Main contact email — used for RFI recipient pre-fill                              |
| `industry`         | String    | Business industry                                                                 |
| `naics_code`       | String    | NAICS classification                                                              |
| `website`          | String    | Company website                                                                   |
| `physical_address` | BelongsTo | Address record                                                                    |

#### `Program`

A payment program that groups LegalEntities together. Defines limits and bank capabilities.

| Field                            | Type          | Meaning                                          |
| -------------------------------- | ------------- | ------------------------------------------------ |
| `name`                           | String        | Program name                                     |
| `legal_entities`                 | HasMany       | Entities on this program                         |
| `program_limits`                 | HasMany       | Spending/receiving limits                        |
| `bank_legal_entities`            | BelongsToMany | Which bank entities service this program         |
| `passthrough_compliance_enabled` | Boolean       | Whether compliance is passed through to the bank |

#### `PersonaInquiry` (Airtable — custom datasource)

Mock Persona inquiry data. Lives in Airtable, served via the custom AirtableDatasource.

| Field               | Type        | Meaning                                                                           |
| ------------------- | ----------- | --------------------------------------------------------------------------------- |
| `id`                | String (PK) | Airtable record ID                                                                |
| `inquiry_id`        | String      | Mock Persona inquiry ID (e.g. `inq_abc123`)                                       |
| `legal_entity_id`   | String      | FK to LegalEntity.id (as string)                                                  |
| `legal_entity_name` | String      | Denormalized name for Airtable readability                                        |
| `status`            | Enum        | `pending`, `approved`, `needs_review`, `failed`                                   |
| `template_type`     | Enum        | `source_of_funds`, `ubo_documentation`, `proof_of_address`, `transaction_purpose` |
| `ubo_verified`      | Boolean     | Whether UBOs have been verified                                                   |
| `ubo_count`         | Number      | Number of UBOs on this entity                                                     |
| `docs_collected`    | String      | Comma-separated list of received documents                                        |
| `docs_missing`      | String      | Comma-separated list of missing documents                                         |
| `one_time_link`     | String      | Persona one-time-link URL (mock)                                                  |
| `notes`             | String      | Operator notes                                                                    |
| `created_at`        | Date        | When the RFI was sent                                                             |
| `responded_at`      | Date        | When the customer responded (nullable)                                            |

---

## 3. Code Customizations

### 3.1 Smart Fields

**`tier`** — C1/C2 derived from relationship graph (on `LegalEntity`)

```ruby
collection.add_field('tier', {
  column_type: 'Enum',
  enum_values: ['C1', 'C2', 'C3'],
  is_read_only: true,
  is_filterable: true
}) do |context|
  if context.record['parent_legal_entity_relationship'].nil?
    'C1'
  else
    'C2'
  end
end
```

**`active_transfers_held_count`** — held transfers count (on `LegalEntity`)

```ruby
collection.add_field('active_transfers_held_count', {
  column_type: 'Number',
  is_read_only: true
}) do |context|
  ActiveRecord::Base.connection.execute(
    "SELECT COUNT(t.id) FROM transfers t
     JOIN accounts a ON t.account_id = a.id
     WHERE a.legal_entity_id = #{context.record['id']}
     AND t.status = 'held'"
  ).first['count'].to_i
end
```

**`kyb_status`** — latest Decision status (on `LegalEntity`)

```ruby
collection.add_field('kyb_status', {
  column_type: 'Enum',
  enum_values: ['passed', 'needs_review', 'failed', 'running', 'expired', 'none'],
  is_read_only: true,
  is_filterable: true
}) do |context|
  latest = context.record['decisions']&.max_by { |d| d['created_at'] }
  latest ? latest['status'] : 'none'
end
```

**`days_held`** — days since hold (on `Transfer`)

```ruby
collection.add_field('days_held', {
  column_type: 'Number',
  is_read_only: true,
  is_sortable: true
}) do |context|
  held_at = context.record['held_at']
  held_at ? ((Time.now - held_at) / 86400).round(1) : nil
end
```

**`sla_status`** — traffic light vs SLA thresholds (on `Transfer`)

```ruby
collection.add_field('sla_status', {
  column_type: 'Enum',
  enum_values: ['ok', 'warning', 'breached'],
  is_read_only: true
}) do |context|
  held_at = context.record['held_at']
  return nil unless held_at
  hours_held = (Time.now - held_at) / 3600
  if hours_held < 3
    'ok'
  elsif hours_held < 6
    'warning'
  else
    'breached'
  end
end
```

**`amount_display`** — cents → formatted dollars (on `Transfer`)

```ruby
collection.add_field('amount_display', {
  column_type: 'String',
  is_read_only: true
}) do |context|
  amount = context.record['amount']
  amount ? "$#{format('%.2f', amount / 100.0)}" : nil
end
```

**`sardine_risk_score`** — risk score from Verification\_\_Sardine.data (on `Transfer`)

```ruby
collection.add_field('sardine_risk_score', {
  column_type: 'Number',
  is_read_only: true
}) do |context|
  sardine = context.record['verifications']&.find { |v| v['type'] == 'Verification::Sardine' }
  sardine ? sardine['data']['risk_score'] : nil
end
```

**`sardine_alert_reason`** — human-readable reason from Sardine JSON (on `Transfer`)

```ruby
collection.add_field('sardine_alert_reason', {
  column_type: 'String',
  is_read_only: true
}) do |context|
  sardine = context.record['verifications']&.find { |v| v['type'] == 'Verification::Sardine' }
  sardine ? sardine['data']['reason'] : nil
end
```

---

### 3.2 Smart Actions

**`Send RFI`** (on `LegalEntity`) — creates a PersonaInquiry in Airtable, returns one-time-link

Scope: `Single` | Approval gate: none

Form:
| Field | Type | Required | Notes |
|---|---|---|---|
| `template_type` | Enum | Yes | `source_of_funds`, `ubo_documentation`, `proof_of_address`, `transaction_purpose` |
| `channel` | Enum | Yes | `persona_link`, `email` — default: `persona_link` |
| `recipient_email` | String | No | Pre-filled from `Business.primary_email` |
| `notes` | String | No | Free text note to customer |

```ruby
collection.add_action('Send RFI', { scope: 'Single', form: [...] }) do |context, result_builder|
  entity = context.get_record(['id'])
  inquiry_id    = "inq_#{SecureRandom.hex(8)}"
  one_time_link = "https://withpersona.com/verify?inquiry-template-id=itmpl_demo&reference-id=#{inquiry_id}"

  airtable_collection = context.datasource.get_collection('PersonaInquiry')
  airtable_collection.create(context.caller, {
    'inquiry_id'      => inquiry_id,
    'legal_entity_id' => entity['id'].to_s,
    'status'          => 'pending',
    'template_type'   => context.form_values['template_type'],
    'one_time_link'   => one_time_link,
    'notes'           => context.form_values['notes'] || '',
    'created_at'      => Time.now.iso8601
  })

  result_builder.success('RFI sent', { type: 'Text', message: "One-time-link: #{one_time_link}" })
end
```

---

**`Enable Payments`** (on `LegalEntity`) — sets status to active

Scope: `Single` | Approval gate: none

Form:
| Field | Type | Required |
|---|---|---|
| `reasoning` | String | Yes |

```ruby
collection.add_action('Enable Payments', { scope: 'Single', form: [...] }) do |context, result_builder|
  entity = context.get_record(['id'])
  LegalEntity.find(entity['id']).update!(status: 'active')
  result_builder.success('Payments enabled')
end
```

---

**`Suspend Entity`** (on `LegalEntity`) — sets status to suspended

Scope: `Single` | Approval gate: **always (four-eyes)**

Form:
| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | Enum | Yes | `fraud_confirmed`, `sanctions_hit`, `compliance_directive`, `customer_request` |
| `reasoning` | String | Yes | Detailed rationale |

```ruby
collection.add_action('Suspend Entity', { scope: 'Single', form: [...] }) do |context, result_builder|
  entity = context.get_record(['id'])
  LegalEntity.find(entity['id']).update!(status: 'suspended')
  result_builder.success('Entity suspended')
end
```

---

**`Release Payment`** (on `Transfer`) — calls Flow API to release hold

Scope: `Single` | Approval gate: **if amount > $10,000 OR risk_rating = high**

Form:
| Field | Type | Required |
|---|---|---|
| `reasoning` | String | Yes |

```ruby
collection.add_action('Release Payment', { scope: 'Single', form: [...] }) do |context, result_builder|
  transfer = context.get_record(['id'])
  response = FlowApiClient.patch("/transfers/#{transfer['id']}/release")
  if response.success?
    result_builder.success('Payment released')
  else
    result_builder.error("Flow API error: #{response.body}")
  end
end
```

---

**`Block Payment`** (on `Transfer`) — calls Flow API to cancel

Scope: `Single` | Approval gate: **always**

Form:
| Field | Type | Required | Notes |
|---|---|---|---|
| `reason` | Enum | Yes | `fraud`, `sanctions`, `compliance_directive`, `suspicious_activity` |
| `reasoning` | String | Yes | Detailed rationale |
| `notify_customer` | Boolean | No | |

```ruby
collection.add_action('Block Payment', { scope: 'Single', form: [...] }) do |context, result_builder|
  transfer = context.get_record(['id'])
  response = FlowApiClient.patch("/transfers/#{transfer['id']}/cancel")
  if response.success?
    result_builder.success('Payment blocked')
  else
    result_builder.error("Flow API error: #{response.body}")
  end
end
```

---

### 3.3 Segments

**`Held Payments`** (on `Transfer`)

```ruby
collection.add_segment('Held Payments') do |_context|
  { field: 'status', operator: 'Equal', value: 'held' }
end
```

**`Onboarding`** (on `LegalEntity`)

```ruby
collection.add_segment('Onboarding') do |_context|
  { field: 'status', operator: 'Equal', value: 'pending' }
end
```

**`High Risk`** (on `LegalEntity`)

```ruby
collection.add_segment('High Risk') do |_context|
  { field: 'risk_rating', operator: 'Equal', value: 'high' }
end
```

**`Active Alerts`** (on `Verification__Sardine`)

```ruby
collection.add_segment('Active Alerts') do |_context|
  { field: 'status', operator: 'Equal', value: 'held' }
end
```

---

### 3.4 Smart Relationship

Only one relationship requires manual declaration — the cross-datasource link between ActiveRecord and Airtable. Everything else is auto-detected.

```ruby
collection.add_external_relation('persona_inquiries', {
  schema: {
    'id'             => 'String',
    'inquiry_id'     => 'String',
    'status'         => 'String',
    'template_type'  => 'String',
    'ubo_verified'   => 'Boolean',
    'ubo_count'      => 'Number',
    'docs_collected' => 'String',
    'docs_missing'   => 'String',
    'one_time_link'  => 'String',
    'notes'          => 'String',
    'created_at'     => 'Date',
    'responded_at'   => 'Date'
  },
  list_records: proc { |record|
    airtable = ForestAdminRails::Datasources::AirtableCollection.instance
    airtable.list_for_entity(record['id'].to_s)
  }
})
```

---

### 3.5 Airtable Datasource

See `airtable_datasource.rb` for full implementation.

**Airtable table: `PersonaInquiries`**

Required columns:

| Column name         | Airtable type    | Notes                                                                                     |
| ------------------- | ---------------- | ----------------------------------------------------------------------------------------- |
| `inquiry_id`        | Single line text | Mock Persona ID, e.g. `inq_abc123`                                                        |
| `legal_entity_id`   | Single line text | Must match LegalEntity.id as string                                                       |
| `legal_entity_name` | Single line text | Denormalized, for Airtable readability                                                    |
| `status`            | Single select    | Values: `pending`, `approved`, `needs_review`, `failed`                                   |
| `template_type`     | Single select    | Values: `source_of_funds`, `ubo_documentation`, `proof_of_address`, `transaction_purpose` |
| `ubo_verified`      | Checkbox         |                                                                                           |
| `ubo_count`         | Number           |                                                                                           |
| `docs_collected`    | Multiple select  | e.g. `certificate_of_incorporation`, `ein_letter`                                         |
| `docs_missing`      | Multiple select  | e.g. `ubo_passport`, `proof_of_address`                                                   |
| `one_time_link`     | URL              | Mock Persona link                                                                         |
| `notes`             | Long text        |                                                                                           |
| `created_at`        | Date             | ISO 8601                                                                                  |
| `responded_at`      | Date             | ISO 8601, leave empty until customer responds                                             |

**Environment variables required:**

```
AIRTABLE_BASE_ID=appXXXXXXXXXXXXXX
AIRTABLE_TABLE_ID=tblXXXXXXXXXXXXXX
AIRTABLE_API_KEY=patXXXXXXXXXXXXXX
```

**How to simulate Persona webhook during demo:**
During the demo, manually change a record's `status` from `pending` to `approved` in Airtable. Forest reads Airtable in real-time — refreshing the PersonaInquiry panel on the LegalEntity will show the updated status immediately.

---
