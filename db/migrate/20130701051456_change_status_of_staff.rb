class ChangeStatusOfStaff < ActiveRecord::Migration
  def change
    change_column :staffs, :status, :integer, :limit => 1  #员工状态
  end
end
