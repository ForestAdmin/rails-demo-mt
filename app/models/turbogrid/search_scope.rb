module Turbogrid
  class SearchScope < ApplicationRecord
    self.table_name = "turbogrid_search_scopes"

    has_many :grid_states, class_name: "Turbogrid::GridState", foreign_key: :search_scope_id
  end
end
