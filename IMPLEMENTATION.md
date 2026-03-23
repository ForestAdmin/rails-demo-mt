# Forest Admin — Modern Treasury Demo: Implementation Summary

## 1. Schema

### Entity model

The data model mirrors the Modern Treasury API structure. All tables live in the `public` schema on Supabase (PostgreSQL).

```
Program
  └── LegalEntity (polymorphic → Business | Individual)
        ├── LegalEntityRelationship (parent ↔ child, e.g. C1 → C2 subsidiary)
        ├── Account
        │     ├── AccountBalance
        │     ├── AccountCapability → BankCapability, ProgramLimit
        │     └── Transfer
        │           ├── Verification::Sardine  (STI, type = "Verification::Sardine")
        │           ├── TransferReference
        │           ├── Transfer::Seasoning
        │           ├── AchNoc
        │           └── Return
        ├── Decision
        │     └── Evaluation (per-check result inside a Decision)
        ├── BankLegalEntity
        ├── Document          (polymorphic)
        └── Identification    (polymorphic)

Address  (used by Business, Individual, Account.party_address)
```

### Key tables

| Table | Notable columns | Enums |
|---|---|---|
| `legal_entities` | `entity_type/id` (polymorphic), `status`, `risk_rating`, `role`, `external_id`, `program_id` | status: active / denied / pending / suspended |
| `businesses` | `business_name`, `primary_email`, `country_of_incorporation`, `legal_structure`, `industry`, `naics_code` | — |
| `individuals` | `first_name`, `last_name`, `primary_email`, `date_of_birth`, `citizenship_country_code` | — |
| `accounts` | `legal_entity_id`, `status`, `currency`, `party_name`, `active_at`, `suspended_at`, `pending_closure_at` | status: active / pending_activation / suspended / pending_closure / closed |
| `account_balances` | `available_amount`, `posted_amount`, `pending_amount` (cents) | — |
| `transfers` | `account_id`, `amount` (cents), `currency`, `payment_type`, `direction`, `status`, `held_at`, `external_id` | status: approved / cancelled / completed / failed / held / pending / processing / returned / sent |
| `verifications` | `transfer_id`, `type` (STI), `status`, `rejection_reason`, `data` (jsonb), `vendor_id` | — |
| `decisions` | `legal_entity_id`, `status`, `expires_at`, `details` (jsonb), `vendor_id`, `resolved_by` | status: passed / needs_review / failed / running / expired |
| `evaluations` | `decision_id`, `legal_entity_id`, `status`, `details` (jsonb) | — |
| `legal_entity_relationships` | `parent_legal_entity_id`, `child_legal_entity_id`, `relationship_types[]`, `ownership_percentage` | — |

---

## 2. Seed data

### Hero scenarios (named records for demo scripts)

| Entity | Scenario | Key data |
|---|---|---|
| **Corner Coffee LLC** | Held payment — fraud review | C2 under Meridian Fintech Group, risk_rating: high, $45,000 wire held ~8.5h, Sardine risk_score: 87, reason: wire_layering_pattern |
| **Fresh Beans Co** | Onboarding blocked — KYB incomplete | status: pending, Decision: needs_review, UBO eval: needs_review, docs: ubo_passport + proof_of_address missing |
| Sunrise Bakery | Onboarding pending | Decision: running |
| Tidal Wave Imports | Onboarding pending | Decision: needs_review |
| Green Path Consulting | Onboarding pending | Decision: failed |

Additional held transfers seeded with varied SLA statuses (ok / warning / breached).

### Bulk data (`db/seeds/bulk.rb`)

Idempotent (guard on `external_id LIKE 'bulk_%'`). Generates:

| Entity | Count |
|---|---|
| C1 LegalEntities (businesses) | 40 |
| C2 LegalEntities (businesses, each linked to a C1) | 120 |
| Individual LegalEntities | 20 |
| Accounts (1-2 per C1, 1 per C2) | ~180 |
| Transfers (3-5 per active account) | ~600 |
| Verification::Sardine (for held transfers) | variable |
| Decisions (1 per LE) | ~160 |
| Evaluations (2-3 per decision) | ~400 |

Total: **192 LegalEntities, ~600 Transfers, ~190 Accounts, ~160 Decisions** — 10+ pages per entity in Forest Admin.

---

## 3. Forest Admin customizations

### Collections registered

| Collection | Source |
|---|---|
| All AR models | ActiveRecord datasource (auto-mapped) |
| `PersonaInquiry` | Custom datasource → Airtable (`AirtableForestDatasource`) |

### Custom datasource — Airtable (`PersonaInquiry`)

**File:** `lib/forest_admin_rails/datasources/airtable_forest_datasource.rb`

Wraps the Airtable API as a proper Forest Admin datasource. PersonaInquiry appears as a standalone collection in the FA sidebar.

**Airtable table fields:**

| Field | Type |
|---|---|
| `legal_entity_id` | Text |
| `status` | Single select: created / pending / completed / expired / failed |
| `template_type` | Single select: source_of_funds / ubo_documentation / proof_of_address / transaction_purpose |
| `docs_collected` | Text |
| `docs_missing` | Text |
| `one_time_link` | URL |
| `ubo_verified` | Checkbox |
| `notes` | Long text |

Demo records seeded: Corner Coffee LLC (status: pending) and Fresh Beans Co (status: created).

---

### Computed fields (Smart Fields)

#### LegalEntity

| Field | Type | Description |
|---|---|---|
| `entity_name` | String | Business.business_name or "First Last" for individuals (batched) |
| `entity_email` | String | primary_email from Business or Individual (batched) |
| `tier` | Enum (C1/C2) | C1 = not a child in any LegalEntityRelationship; C2 = child |
| `active_transfers_held_count` | Number | Count of held transfers across all accounts (SQL batch) |
| `kyb_status` | Enum | Latest Decision status: passed / needs_review / failed / running / expired / none |

#### Transfer

| Field | Type | Description |
|---|---|---|
| `days_held` | Number | Days since held_at (rounded to 1 decimal) |
| `sla_status` | Enum (ok/warning/breached) | ok < 3h, warning < 6h, breached ≥ 6h |
| `amount_display` | String | Cents → "$X,XXX.XX" |
| `sardine_risk_score` | Number | risk_score from Verification::Sardine.data JSON (batched) |
| `sardine_alert_reason` | String | reason from Verification::Sardine.data JSON (batched) |
| `owner_name` | String | Transfer → Account → LegalEntity → Business/Individual name (batched, 3-hop) |

#### Account

| Field | Type | Description |
|---|---|---|
| `available_balance` | String | AccountBalance.available_amount formatted as "$X.XX" (batched) |
| `posted_balance` | String | AccountBalance.posted_amount formatted as "$X.XX" (batched) |

#### Decision

| Field | Type | Description |
|---|---|---|
| `days_until_expiry` | Number | Days until expires_at (negative = already expired) |
| `expiry_status` | Enum (ok/expiring_soon/expired) | expiring_soon < 30 days |

---

### Segments

| Collection | Segment | Filter |
|---|---|---|
| LegalEntity | Onboarding | status = pending |
| LegalEntity | High Risk | risk_rating = high |
| Transfer | Held Payments | status = held |
| Decision | Needs Review | status = needs_review |
| Decision | Expiring Soon | expires_at present AND < 30 days from now |
| Verification__Sardine | Active Alerts | status = held |
| Account | Active | status = active |
| Account | Suspended | status = suspended |

---

### Custom search

#### LegalEntity

Replaces default search to query across `external_id`, `entity_name` (computed), and `entity_email` (computed) — all case-insensitive contains.

---

### Smart Actions

#### LegalEntity

| Action | Scope | Form fields | Effect |
|---|---|---|---|
| **Send RFI** | Single | Template type (Enum), Channel (Enum), Recipient email (String), Notes (String) | Generates a Persona one-time link (stub). Production: POST /api/v1/inquiries on Persona API |
| **Enable Payments** | Single | Reasoning (String) | Sets LegalEntity.status = active |
| **Suspend Entity** | Single | Reason (Enum), Reasoning (String) | Sets LegalEntity.status = suspended |

#### Account

| Action | Scope | Form fields | Effect |
|---|---|---|---|
| **Freeze Account** | Single | Reason (Enum), Notes (String) | status → suspended, suspended_at = now. Guard: already suspended → error |
| **Unfreeze Account** | Single | Notes (String) | status → active, active_at = now, suspended_at = nil. Guard: not suspended → error |
| **Initiate Account Closure** | Single | Reason (Enum), Notes (String), Notify customer (Boolean) | status → pending_closure, pending_closure_at = now. Guard: already pending_closure or closed → error |

#### Transfer

| Action | Scope | Form fields | Effect |
|---|---|---|---|
| **Release Payment** | Single | Reasoning (String) | FlowApiClient.patch("/transfers/:id/release") |
| **Release Held Payments** | Bulk | Reasoning (String) | Releases all selected transfers with status = held |
| **Block Payment** | Single | Reason (Enum), Reasoning (String), Notify customer (Boolean) | FlowApiClient.patch("/transfers/:id/cancel") |
| **Sanctions Rescan** | Bulk | Notes (String, optional) | Resubmits all non-cancelled transfers for Sardine screening via FlowApiClient.patch("/transfers/:id/rescan"). Production: POST /api/v1/transfers/:id/rescan on Sardine API |

#### Decision

| Action | Scope | Form fields | Effect |
|---|---|---|---|
| **Resolve Decision** | Single | Notes (String, optional) | status → passed, resolved_by = current user email. Guard: only needs_review → error |

---

## 4. External integrations

### FlowApiClient

Stub client (`lib/flow_api_client.rb`) that simulates Modern Treasury API calls (patch, release, cancel, rescan). Returns `{ success: true }` in demo mode.

### Persona API (annotated, not yet wired)

Send RFI contains commented production equivalent:
- `POST https://withpersona.com/api/v1/inquiries` with `Authorization: Bearer PERSONA_API_KEY`
- Returns inquiry ID + session token → one-time link

### Sardine API (annotated, not yet wired)

Sanctions Rescan contains commented production equivalent:
- `POST https://api.sardine.ai/v1/transfers/:id/rescan` with `Authorization: Bearer SARDINE_API_KEY`

---

## 5. Pending / next steps

| Task | Notes |
|---|---|
| Airtable filter on `legal_entity_id` | `AirtableForestCollection#list` ignores filters. Needs `extract_formula` to translate FA condition → Airtable formula so PersonaInquiry workspace panel filters by entity |
| Forest Admin UI — Teams | Create Operations + Compliance teams |
| Forest Admin UI — Collection visibility | Hide ~15 internal collections per team (AchNoc, Book, Return, etc.) |
| Forest Admin UI — Workspaces | "Held Payments" (Operations) + "Compliance Queue" (Compliance) — see demo_plan.md |
| Forest Admin UI — Approval gate | Release Payment: require approval when amount > $10k OR risk_rating = high |
| Zendesk / mock tickets | Option A: Airtable ZendeskTickets table (same datasource pattern). Option B: Zendesk 14-day free trial |
