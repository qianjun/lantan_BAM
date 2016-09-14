class AddRemarkToMatInOrders < ActiveRecord::Migration
  def change
    add_column :mat_in_orders, :remark, :text
    add_column :mat_out_orders, :order_id, :integer
  end
end
