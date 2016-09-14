class CreateRoleMenuRelations < ActiveRecord::Migration
  #权限菜单表
  def change
    create_table :role_menu_relations do |t|
      t.integer :role_id
      t.integer :menu_id

    end

    add_index :role_menu_relations, :role_id
    add_index :role_menu_relations, :menu_id
  end
end
