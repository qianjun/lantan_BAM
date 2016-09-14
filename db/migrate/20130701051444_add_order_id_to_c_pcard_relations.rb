class AddOrderIdToCPcardRelations < ActiveRecord::Migration
  def change
    add_column :c_pcard_relations, :order_id, :integer
    add_index :c_pcard_relations, :order_id
  end
end
