class CreateSearchtweets < ActiveRecord::Migration
  def change
    create_table :searchtweets do |t|
      t.string :text, limit: 140
      t.string :ironic
      t.timestamps null: false
    end
  end
end
