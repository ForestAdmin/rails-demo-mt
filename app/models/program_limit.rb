class ProgramLimit < ApplicationRecord
  belongs_to :program
  has_many :program_entitlements
end
