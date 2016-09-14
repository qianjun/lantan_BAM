class AddStoreIdToCustomerNumRelation < ActiveRecord::Migration
  def change
    add_column :customer_num_relations, :store_id, :integer
    change_column :customers, :total_point, :integer,:default=>0
  end
end
