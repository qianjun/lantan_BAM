class CreateMatDepotRelations < ActiveRecord::Migration
  def change  #物料仓库表
    create_table :mat_depot_relations do |t|
      t.integer :depot_id  #仓库id
      t.integer :material_id
      t.integer :storage  #仓库存量
      t.integer :status  #物料存放仓库的状态包括删除等
      t.timestamps
    end
    add_index :mat_depot_relations,:depot_id
    add_index :mat_depot_relations,:material_id
  end
end
