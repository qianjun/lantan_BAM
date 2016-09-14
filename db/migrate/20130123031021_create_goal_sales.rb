class CreateGoalSales < ActiveRecord::Migration
  #销售额度表
  def change
    create_table :goal_sales do |t|
      t.datetime :started_at
      t.datetime :ended_at
      t.string :type_name
      t.float :goal_price   #目标额度
      t.float :current_price  
      t.integer :store_id

      t.datetime :created_at
    end

    add_index :goal_sales, :created_at
    add_index :goal_sales, :store_id
  end
end
