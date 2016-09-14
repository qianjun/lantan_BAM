class ChangeCategoryIdToSvcardProdRelations < ActiveRecord::Migration
  def change
    change_column :svcard_prod_relations, :category_id, :string
  end
end
