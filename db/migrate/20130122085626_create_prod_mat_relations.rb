class CreateProdMatRelations < ActiveRecord::Migration
  #产品物料表
  def change
    create_table :prod_mat_relations do |t|
      t.integer :product_id
      t.integer :material_num
      t.integer :material_id

    end

    add_index :prod_mat_relations, :product_id
    add_index :prod_mat_relations, :material_id
  end
end
