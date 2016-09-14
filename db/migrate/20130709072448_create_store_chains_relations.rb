class CreateStoreChainsRelations < ActiveRecord::Migration
  def change  #门店连锁店关系表
    create_table :store_chains_relations do |t|
      t.integer :chain_id  #连锁店
      t.integer :store_id  #门店id
      t.timestamps
    end
    add_index :store_chains_relations, :chain_id
    add_index :store_chains_relations, :store_id
  end
end
