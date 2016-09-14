class AddCategoryIdToSvcardProdRelations < ActiveRecord::Migration
  def change
    add_column :svcard_prod_relations, :category_id, :integer
  end
end
