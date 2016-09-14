class AddWorkingStatsToStaffGrRecords < ActiveRecord::Migration
  def change
    add_column :staff_gr_records, :working_stats, :integer    #在职状态 0试用 1正式
  end
end
