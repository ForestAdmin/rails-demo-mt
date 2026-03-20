class Verification < ApplicationRecord
  belongs_to :transfer

  enum :status, { held: "held", passed: "passed", processing: "processing", rejected: "rejected" }, prefix: true
end
