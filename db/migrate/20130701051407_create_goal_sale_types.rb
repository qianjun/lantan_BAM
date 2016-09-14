class CreateGoalSaleTypes < ActiveRecord::Migration
  def change
    create_table :goal_sale_types do |t|
      t.string :type_name
      t.integer :goal_sale_id
      t.float :goal_price,:default=>0
      t.float :current_price,:default=>0
      t.integer :types
    end

    add_index :goal_sale_types, :type_name
    add_index :goal_sale_types, :goal_sale_id
    add_index :goal_sale_types, :types
  end
end
