class AddStationIdToEquipmentInfos < ActiveRecord::Migration
  def change
    add_column :equipment_infos, :station_id, :integer
  end
end
