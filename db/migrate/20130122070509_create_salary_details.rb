class CreateSalaryDetails < ActiveRecord::Migration
  def change
    create_table :salary_details do |t|
      t.integer :current_day  #年月日
      t.integer :deduct_num   #扣款次数
      t.integer :reward_num   #奖励次数
      t.float :satisfied_perc  #满意度
      t.integer :staff_id
      t.integer :voilation_reward_id 

      t.datetime :created_at
    end

    add_index :salary_details, :current_day
    add_index :salary_details, :staff_id
    add_index :salary_details, :voilation_reward_id
  end
end
