class CreateEquipmentInfos < ActiveRecord::Migration
  def change
    create_table :equipment_infos do |t|
      t.integer :store_id
      t.integer :station_id
      t.float :water_num
      t.float :gas_num
      t.integer :status, :default => 0
      t.timestamps
    end
    add_index :equipment_infos, :store_id
    add_index :equipment_infos, :station_id
    add_index :equipment_infos, :created_at
  end
end
