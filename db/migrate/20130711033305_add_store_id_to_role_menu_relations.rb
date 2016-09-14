class AddStoreIdToRoleMenuRelations < ActiveRecord::Migration
  def change
    add_column :role_menu_relations, :store_id, :integer
  end
end
