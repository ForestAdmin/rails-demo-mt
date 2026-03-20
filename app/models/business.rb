class Business < ApplicationRecord
  belongs_to :physical_address, class_name: "Address", optional: true
  belongs_to :primary_address, class_name: "Address", optional: true

  enum :legal_structure, { corporation: "corporation", llc: "llc", non_profit: "non_profit", partnership: "partnership", sole_proprietorship: "sole_proprietorship", trust: "trust" }
end
