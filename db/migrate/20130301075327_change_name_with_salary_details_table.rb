class ChangeNameWithSalaryDetailsTable < ActiveRecord::Migration
  def up
    rename_column :salary_details, :voilation_reward_id, :violation_reward_id
  end

  def down
  end
end
