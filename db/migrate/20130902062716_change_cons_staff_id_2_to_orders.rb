class ChangeConsStaffId2ToOrders < ActiveRecord::Migration
  change_column :orders,:cons_staff_id_2,:integer
end
