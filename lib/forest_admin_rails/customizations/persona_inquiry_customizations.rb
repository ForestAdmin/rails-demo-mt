module ForestAdminRails
  module Customizations
    module PersonaInquiryCustomizations
      def self.apply(agent)
        # ManyToOne: PersonaInquiry → LegalEntity (cross-datasource: Airtable → Postgres)
        # legal_entity_id in Airtable is stored as a String matching LegalEntity.id (Integer).
        # FA's emulated relation layer handles the type coercion at query time.
        agent.customize_collection("PersonaInquiry") do |collection|
          collection.add_relation("legal_entity", {
            type:                "ManyToOne",
            foreign_collection:  "LegalEntity",
            foreign_key:         "legal_entity_id",
            foreign_key_target:  "id"
          })
        end

        # OneToMany: LegalEntity → PersonaInquiry (inverse, for relation panels)
        agent.customize_collection("LegalEntity") do |collection|
          collection.add_relation("persona_inquiries", {
            type:               "OneToMany",
            foreign_collection: "PersonaInquiry",
            origin_key:         "legal_entity_id",
            origin_key_target:  "id"
          })
        end
      end
    end
  end
end
