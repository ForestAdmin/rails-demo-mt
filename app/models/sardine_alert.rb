class SardineAlert < ApplicationRecord
  belongs_to :legal_entity
  belongs_to :payment_order, optional: true

  has_one :case, class_name: "InvestigationCase", dependent: :destroy
end
