class ModifyDeductNumAndRewardNumToFloat < ActiveRecord::Migration
  def up
    change_column :salary_details,:deduct_num,:float
    change_column :salary_details,:reward_num,:float
    change_column :salaries,:deduct_num,:float
    change_column :salaries,:reward_num,:float
  end

  def down
    change_column :salary_details,:deduct_num,:integer
    change_column :salary_details,:reward_num,:integer
    change_column :salaries,:deduct_num,:integer
    change_column :salaries,:reward_num,:integer
  end
end
