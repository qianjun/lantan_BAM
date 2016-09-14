class CreateSvcardProdRelations < ActiveRecord::Migration
  #储值卡产品关系表
  def change
    create_table :svcard_prod_relations do |t|
      t.integer :product_id
      t.integer :product_num
      t.integer :sv_card_id

    end

    add_index :svcard_prod_relations, :product_id
    add_index :svcard_prod_relations, :sv_card_id
  end
end
