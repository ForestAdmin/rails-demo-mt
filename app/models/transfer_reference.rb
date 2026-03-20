class TransferReference < ApplicationRecord
  belongs_to :transfer

  enum :reference_type, {
    ach_original_trace_number: "ach_original_trace_number",
    ach_trace_number: "ach_trace_number",
    blockchain_transaction_hash: "blockchain_transaction_hash",
    fedwire_imad: "fedwire_imad",
    fedwire_omad: "fedwire_omad",
    swift_mir: "swift_mir",
    swift_uetr: "swift_uetr"
  }, prefix: true
end
