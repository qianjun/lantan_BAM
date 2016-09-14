class AddHasStationControllerAndCostTime < ActiveRecord::Migration
  def change
    add_column :work_orders, :cost_time, :integer
    add_column :stations, :is_has_controller, :boolean
  end
end
