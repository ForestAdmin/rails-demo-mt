class BankLegalEntity < ApplicationRecord
  belongs_to :legal_entity

  enum :entity, { cross_river: "cross_river", example1: "example1", paxos: "paxos" }, prefix: true
  enum :status, { closed: "closed", completed: "completed", denied: "denied", failed: "failed", processing: "processing", suspended: "suspended" }, prefix: true
end
