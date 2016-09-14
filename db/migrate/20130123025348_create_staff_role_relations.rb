class CreateStaffRoleRelations < ActiveRecord::Migration
  #员工权限表
  def change
    create_table :staff_role_relations do |t|
      t.integer :role_id
      t.integer :staff_id

    end

    add_index :staff_role_relations, :role_id
    add_index :staff_role_relations, :staff_id
  end
end
