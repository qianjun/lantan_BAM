class AddTypesToViolationRewards < ActiveRecord::Migration
  def change
    add_column :violation_rewards, :belong_types, :integer
  end
end
