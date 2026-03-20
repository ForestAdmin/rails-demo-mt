class ProgramEntitlement < ApplicationRecord
  belongs_to :bank_capability, optional: true
  belongs_to :program_limit, optional: true
end
