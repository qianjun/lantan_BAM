class CreateSalaries < ActiveRecord::Migration
  def change
    create_table :salaries do |t|
      t.integer :deduct_num
      t.integer :reward_num
      t.float :total
      t.integer :current_month  #年月
      t.integer :staff_id 
      t.integer :satisfied_perc  #满意程度

      t.datetime :created_at
    end

    add_index :salaries, :current_month
    add_index :salaries, :staff_id
  end
end
