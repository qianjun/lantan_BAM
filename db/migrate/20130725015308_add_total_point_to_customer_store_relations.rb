class AddTotalPointToCustomerStoreRelations < ActiveRecord::Migration
  def change
    add_column :customer_store_relations,:total_point,:integer
    add_column :customer_store_relations,:is_vip,:boolean, :default => 0
  end
end

