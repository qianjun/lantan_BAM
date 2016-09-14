class AddProductDiscountToSvcardProdRelations < ActiveRecord::Migration
  def change
    add_column :svcard_prod_relations, :product_discount, :integer
  end
end
