class Identification < ApplicationRecord
  belongs_to :identifiable, polymorphic: true, optional: true
end
