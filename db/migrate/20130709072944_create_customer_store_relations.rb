class CreateCustomerStoreRelations < ActiveRecord::Migration
  def change #门店客户表
    create_table :customer_store_relations do |t|
      t.integer :customer_id
      t.integer :store_id
      t.timestamps
    end
    add_index :customer_store_relations,:customer_id
    add_index :customer_store_relations,:store_id
  end
end
