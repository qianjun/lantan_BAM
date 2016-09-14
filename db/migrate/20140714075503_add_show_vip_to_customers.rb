class AddShowVipToCustomers < ActiveRecord::Migration
  def change
    add_column :customers, :show_vip, :boolean,:default=>0
  end
end
