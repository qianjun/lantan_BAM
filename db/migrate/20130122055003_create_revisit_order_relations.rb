class CreateRevisitOrderRelations < ActiveRecord::Migration
  def change
    create_table :revisit_order_relations do |t|
      t.integer :revisit_id
      t.integer :order_id

    end

    add_index :revisit_order_relations, :revisit_id
    add_index :revisit_order_relations, :order_id
  end
end
