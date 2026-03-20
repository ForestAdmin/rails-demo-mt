class Program < ApplicationRecord
  has_many :legal_entities
  has_many :program_limits
end
