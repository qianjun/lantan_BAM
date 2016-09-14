class ChangeTypeToWordOrders < ActiveRecord::Migration
  change_column :work_orders,:water_num,:float
  change_column :work_orders,:electricity_num,:float
  change_column :work_orders,:violation_num,:float
  change_column :work_orders,:runtime,:float
  change_column :work_records,:water_num,:float
  change_column :work_records,:elec_num,:float
  change_column :work_records,:violation_num,:float
end
