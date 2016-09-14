class AddStoreIdToMatOutOrders < ActiveRecord::Migration
  def change
    add_column :mat_out_orders, :store_id, :integer
  end
end
