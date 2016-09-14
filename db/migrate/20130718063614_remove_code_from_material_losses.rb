class RemoveCodeFromMaterialLosses < ActiveRecord::Migration
  def up
    remove_column :material_losses, :code
    remove_column :material_losses, :name
    remove_column :material_losses, :types
    remove_column :material_losses, :specifications
    remove_column :material_losses, :price
    remove_column :material_losses, :sale_price
    add_column :material_losses, :material_id, :integer
    add_index :material_losses, :material_id
  end
  def down
    add_column :material_losses, :code ,:integer
    add_column :material_losses, :name  ,:integer
    add_column :material_losses, :types  ,:integer
    add_column :material_losses, :specifications   ,:integer
    add_column :material_losses, :price   ,:integer
    add_column :material_losses, :sale_price  ,:integer
    remove_column :material_losses, :material_id
    remove_index! :material_losses, :material_id
  end
end
