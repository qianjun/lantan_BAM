class AddStoreIdToStationStaffRelations < ActiveRecord::Migration
  def change
    add_column :station_staff_relations, :store_id, :integer
    add_index :station_staff_relations, :store_id
  end
end
