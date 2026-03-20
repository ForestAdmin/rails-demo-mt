class LegalEntityRelationship < ApplicationRecord
  belongs_to :parent_legal_entity, class_name: "LegalEntity"
  belongs_to :child_legal_entity, class_name: "LegalEntity"
end
