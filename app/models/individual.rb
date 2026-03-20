class Individual < ApplicationRecord
  belongs_to :primary_address, class_name: "Address", optional: true
end
