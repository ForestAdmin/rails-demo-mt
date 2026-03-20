module Turbogrid
  class GridState < ApplicationRecord
    self.table_name = "turbogrid_grid_states"

    belongs_to :search_scope, class_name: "Turbogrid::SearchScope"
  end
end
