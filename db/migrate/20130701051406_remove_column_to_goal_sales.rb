class RemoveColumnToGoalSales < ActiveRecord::Migration
  def up
    remove_column :goal_sales, :goal_price
    remove_column :goal_sales, :type_name
    remove_column :goal_sales, :current_price
  end

  def down
    add_column :goal_sales, :current_price, :integer
    add_column :goal_sales, :type_name, :string
    add_column :goal_sales, :goal_price, :integer
  end
end
