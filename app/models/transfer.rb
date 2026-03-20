class Transfer < ApplicationRecord
  belongs_to :account
  belongs_to :account_capability, optional: true

  has_many :transfer_references
  has_many :seasonings, class_name: "Transfer::Seasoning"
  has_many :verifications
  has_one :return, class_name: "Return", foreign_key: :original_transfer_id
  has_one :source_return, class_name: "Return", foreign_key: :return_transfer_id
  has_one :originating_book, class_name: "Book", foreign_key: :originating_transfer_id
  has_one :receiving_book, class_name: "Book", foreign_key: :receiving_transfer_id

  enum :payment_type, { ach: "ach", book: "book", card: "card", ethereum: "ethereum", rtp: "rtp", solana: "solana", wire: "wire" }, prefix: true
  enum :direction, { credit: "credit", debit: "debit" }, prefix: true
  enum :status, { approved: "approved", cancelled: "cancelled", completed: "completed", failed: "failed", held: "held", pending: "pending", processing: "processing", returned: "returned", sent: "sent" }, prefix: true
  enum :transfer_type, { payment: "payment", return: "return", reversal: "reversal" }, prefix: true
  enum :account_role, { originating: "originating", receiving: "receiving" }, prefix: true
end
