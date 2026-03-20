class Return < ApplicationRecord
  belongs_to :original_transfer, class_name: "Transfer", optional: true
  belongs_to :return_transfer, class_name: "Transfer", optional: true
end
