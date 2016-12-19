class AddColumnOriginIdToSearchtweets < ActiveRecord::Migration
  def change
    add_column :searchtweets, :origin_id, :string
  end
end
