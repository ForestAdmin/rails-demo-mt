class CaseEvent < ApplicationRecord
  belongs_to :investigation_case, foreign_key: :case_id
end
