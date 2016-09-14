class CreateCarts < ActiveRecord::Migration
  def change
    create_table :carts do |t|
      t.integer :target_types
      t.integer :target_id
      t.integer :customer_id
      t.integer :store_id
      t.integer :target_num
      t.decimal :target_price,:default=>0,:precision=>"20,2"
      t.integer :status,:default=>0
      t.timestamps
    end
  end
end
