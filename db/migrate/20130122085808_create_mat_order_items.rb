class CreateMatOrderItems < ActiveRecord::Migration
  #物料订单条目表
  def change
    create_table :mat_order_items do |t|
      t.integer :material_order_id
      t.integer :material_id
      t.integer :material_num
      t.float :price
      t.text  :detailed_list

      t.timestamps
    end

    add_index :mat_order_items, :material_order_id
    add_index :mat_order_items, :material_id
  end
end
