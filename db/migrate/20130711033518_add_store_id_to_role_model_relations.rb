class AddStoreIdToRoleModelRelations < ActiveRecord::Migration
  def change
    add_column :role_model_relations, :store_id, :integer
  end
end
