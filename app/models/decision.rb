class Decision < ApplicationRecord
  belongs_to :legal_entity
  has_many :evaluations

  enum :status, { expired: "expired", failed: "failed", needs_review: "needs_review", passed: "passed", running: "running" }, prefix: true
end
