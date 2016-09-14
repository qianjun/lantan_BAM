class AddScoreNumAndSalaryNumToViolationRewards < ActiveRecord::Migration
  def change
    add_column :violation_rewards, :score_num, :float #按分值算
    add_column :violation_rewards, :salary_num, :float #按金额算
  end
end
