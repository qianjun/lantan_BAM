class AddModelNameToRoleModelRelations < ActiveRecord::Migration
  def change
    add_column :role_model_relations, :model_name, :string
  end
end
