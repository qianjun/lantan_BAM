class AddRemarkToMaterialLosses < ActiveRecord::Migration
  def change
    add_column :material_losses, :remark, :string
  end
end
