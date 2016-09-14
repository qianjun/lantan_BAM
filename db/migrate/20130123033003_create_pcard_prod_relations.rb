class CreatePcardProdRelations < ActiveRecord::Migration
  #套餐卡产品表
  def change
    create_table :pcard_prod_relations do |t|
      t.integer :product_id
      t.integer :product_num
      t.integer :package_card_id

    end

    add_index :pcard_prod_relations, :product_id
    add_index :pcard_prod_relations, :package_card_id
  end
end
