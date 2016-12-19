class AddColumnOriginIdToSearches < ActiveRecord::Migration
  def change
    add_column :searches, :origin_id, :string
  end
end
