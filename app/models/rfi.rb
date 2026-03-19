class Rfi < ApplicationRecord
  belongs_to :investigation_case, foreign_key: :case_id
  belongs_to :legal_entity
end
