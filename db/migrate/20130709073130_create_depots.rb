class CreateDepots < ActiveRecord::Migration
  def change #仓库表
    create_table :depots do |t|
      t.string :name 
      t.integer :status
      t.integer :store_id
      t.timestamps
    end
    add_index :depots,:store_id
  end
end
