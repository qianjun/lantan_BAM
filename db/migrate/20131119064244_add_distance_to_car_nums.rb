class AddDistanceToCarNums < ActiveRecord::Migration
  def change
    add_column :car_nums, :distance, :integer, :default => 0 #行驶里程
  end
end