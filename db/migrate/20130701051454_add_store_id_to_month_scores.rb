class AddStoreIdToMonthScores < ActiveRecord::Migration
  def change
    add_column :month_scores, :store_id, :integer
  end
end
