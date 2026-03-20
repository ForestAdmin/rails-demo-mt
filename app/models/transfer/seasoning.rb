class Transfer::Seasoning < ApplicationRecord
  self.table_name = "transfer_seasonings"

  belongs_to :transfer

  enum :status, { completed: "completed", pending: "pending" }, prefix: true
end
