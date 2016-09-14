class RemoveViolationRewardIdFromSalaryDetailsAndAddProcessAtToViolationRewards < ActiveRecord::Migration
  def up
    add_column :violation_rewards, :process_at, :datetime
    remove_column :salary_details, :violation_reward_id
  end

  def down
    remove_column :violation_rewards, :process_at
    add_column :salary_details, :violation_reward_id, :id
  end
end
