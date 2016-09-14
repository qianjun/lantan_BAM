class CreateStationServiceRelations < ActiveRecord::Migration
  def change
    create_table :station_service_relations do |t|
      t.integer :station_id
      t.integer :product_id

      t.timestamps
    end

    add_index :station_service_relations, :station_id
    add_index :station_service_relations, :product_id
  end
end
