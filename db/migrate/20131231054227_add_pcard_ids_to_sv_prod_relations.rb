class AddPcardIdsToSvProdRelations < ActiveRecord::Migration
  def change
    add_column :svcard_prod_relations, :pcard_ids, :string
  end
end
