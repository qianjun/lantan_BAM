class AddStoreIdToRoles < ActiveRecord::Migration
  def change
    add_column :roles, :store_id, :integer
    add_column :roles, :role_type, :integer
  end
end
