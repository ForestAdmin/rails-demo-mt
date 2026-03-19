class LegalEntity < ApplicationRecord
  belongs_to :parent, class_name: "LegalEntity", optional: true
  belongs_to :tam, class_name: "Operator", optional: true

  has_many :children, class_name: "LegalEntity", foreign_key: :parent_id, dependent: :nullify
  has_many :payment_orders, dependent: :destroy
  has_many :sardine_alerts, dependent: :destroy
  has_many :cases, class_name: "InvestigationCase", dependent: :destroy
  has_many :rfis, dependent: :destroy
  has_many :persona_inquiries, dependent: :destroy
end
