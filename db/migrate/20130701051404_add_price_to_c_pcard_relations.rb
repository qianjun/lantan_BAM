class AddPriceToCPcardRelations < ActiveRecord::Migration
  def change
    add_column :c_pcard_relations, :price, :float
  end
end
