class AddStaffLevelToStations < ActiveRecord::Migration
  def change
    add_column :stations, :staff_level, :integer
    add_column :stations, :staff_level1, :integer
  end
end
