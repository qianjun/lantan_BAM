class CreateOPcardRelations < ActiveRecord::Migration
  def change
    create_table :o_pcard_relations do |t|
      t.integer :order_id
      t.integer :c_pcard_relation_id
      t.integer :product_id
      t.integer :product_num
    end
  end
end
