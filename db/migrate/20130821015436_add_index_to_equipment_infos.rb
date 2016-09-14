class AddIndexToEquipmentInfos < ActiveRecord::Migration
  def change
    add_index :equipment_infos, :station_id
    add_index :stores, :code
  end
end
