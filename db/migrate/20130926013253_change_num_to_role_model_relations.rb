class ChangeNumToRoleModelRelations < ActiveRecord::Migration
 change_column :role_model_relations, :num, :bigint
end
