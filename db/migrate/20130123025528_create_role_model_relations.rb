class CreateRoleModelRelations < ActiveRecord::Migration
  #权限功能表
  def change
    create_table :role_model_relations do |t|
      t.integer :role_id
      t.integer :num

    end

    add_index :role_model_relations, :role_id
  end
end
