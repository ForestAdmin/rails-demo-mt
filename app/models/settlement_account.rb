class SettlementAccount < ApplicationRecord
  belongs_to :account
  has_many :account_capabilities

  enum :status, { active: "active", failed: "failed", pending: "pending" }, prefix: true
end
