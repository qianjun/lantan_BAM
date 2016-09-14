class AddDetialToSvcardProdRelations < ActiveRecord::Migration
  def change
    add_column :svcard_prod_relations, :base_price, :float
    add_column :svcard_prod_relations, :more_price, :float
  end
end
