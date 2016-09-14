class ModifyEquipmentInfos < ActiveRecord::Migration
  def up
    remove_column :equipment_infos, :station_id
    remove_column :equipment_infos, :water_num
    remove_column :equipment_infos, :gas_num
    remove_column :equipment_infos, :status
    add_column :equipment_infos, :current_day, :integer
    add_column :equipment_infos, :num, :integer
  end

  def down
    add_column :equipment_infos, :station_id, :integer
    add_column :equipment_infos, :water_num, :float
    add_column :equipment_infos, :gas_num, :float
    add_column :equipment_infos, :status, :integer
    remove_column :equipment_infos, :current_day
    remove_column :equipment_infos, :num
  end
end
