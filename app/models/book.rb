class Book < ApplicationRecord
  belongs_to :originating_transfer, class_name: "Transfer", optional: true
  belongs_to :receiving_transfer, class_name: "Transfer", optional: true
end
