class Operator < ApplicationRecord
  has_many :assigned_cases, class_name: "InvestigationCase", foreign_key: :assigned_to, dependent: :nullify
  has_many :managed_entities, class_name: "LegalEntity", foreign_key: :tam_id, dependent: :nullify

  validates :email, uniqueness: true
end
