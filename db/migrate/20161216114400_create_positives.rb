class CreatePositives < ActiveRecord::Migration
  def change
    create_table :positives do |t|
      t.string "expression"
      t.timestamps null: false
    end
  end
end
