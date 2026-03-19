class PaymentOrder < ApplicationRecord
  belongs_to :legal_entity

  has_many :sardine_alerts, dependent: :destroy
  has_one :case, class_name: "InvestigationCase", dependent: :destroy
end
