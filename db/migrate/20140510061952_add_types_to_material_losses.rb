class AddTypesToMaterialLosses < ActiveRecord::Migration
  def change
    add_column :material_losses, :types, :integer,:default=>0
  end
end
