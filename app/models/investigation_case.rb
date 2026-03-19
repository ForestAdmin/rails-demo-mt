class InvestigationCase < ApplicationRecord
  self.table_name = "cases"

  belongs_to :legal_entity
  belongs_to :payment_order, optional: true
  belongs_to :sardine_alert, optional: true
  belongs_to :assigned_operator, class_name: "Operator", foreign_key: :assigned_to, optional: true

  has_many :case_events, foreign_key: :case_id, dependent: :destroy
  has_many :rfis, foreign_key: :case_id, dependent: :destroy
end
