class Evaluation < ApplicationRecord
  belongs_to :decision
  belongs_to :legal_entity

  enum :status, { expired: "expired", failed: "failed", needs_review: "needs_review", passed: "passed", running: "running" }, prefix: true
end
