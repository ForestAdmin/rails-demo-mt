class AddMissingUpdatedAt < ActiveRecord::Migration[8.0]
  def change
    add_column :case_events, :updated_at, :datetime, null: false, default: -> { "now()" }
    add_column :operators, :updated_at, :datetime, null: false, default: -> { "now()" }
  end
end
