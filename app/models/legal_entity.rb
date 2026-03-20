class LegalEntity < ApplicationRecord
  belongs_to :entity, polymorphic: true, optional: true
  belongs_to :program, optional: true

  has_many :accounts
  has_many :bank_legal_entities
  has_many :decisions
  has_many :child_legal_entity_relationships, class_name: "LegalEntityRelationship", foreign_key: :parent_legal_entity_id
  has_one :parent_legal_entity_relationship, class_name: "LegalEntityRelationship", foreign_key: :child_legal_entity_id

  enum :role, { limited: "limited", standard: "standard" }
  enum :status, { active: "active", denied: "denied", pending: "pending", suspended: "suspended" }
  enum :risk_rating, { high: "high", low: "low", medium: "medium" }
end
