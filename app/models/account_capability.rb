class AccountCapability < ApplicationRecord
  belongs_to :account
  belongs_to :bank_capability, optional: true
  belongs_to :settlement_account, optional: true
  belongs_to :program_limit, optional: true
end
