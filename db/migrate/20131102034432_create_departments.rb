class CreateDepartments < ActiveRecord::Migration
  def change
    create_table :departments do |t|
      t.string :name
      t.integer :types
      t.integer :dpt_id
      t.integer :dpt_lv
      t.integer :store_id
      t.integer :status

      t.timestamps
    end
  end
end
