class CreateSarcastics < ActiveRecord::Migration
  def change
    create_table :sarcastics do |t|
      t.string :text, limit: 140
      t.string :ironic
      t.timestamps null: false
    end
  end
end
