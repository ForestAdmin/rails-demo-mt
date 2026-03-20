class Account < ApplicationRecord
  belongs_to :legal_entity
  belongs_to :party_address, class_name: "Address", optional: true

  has_one :account_balance
  has_many :account_capabilities
  has_many :settlement_accounts
  has_many :transfers

  enum :status, { active: "active", closed: "closed", pending_activation: "pending_activation", pending_closure: "pending_closure", suspended: "suspended" }, prefix: true
end
