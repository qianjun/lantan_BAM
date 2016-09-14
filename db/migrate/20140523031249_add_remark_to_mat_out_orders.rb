class AddRemarkToMatOutOrders < ActiveRecord::Migration
  def change
    add_column :mat_out_orders, :remark, :text
  end
end
