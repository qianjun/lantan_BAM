class AddCapNameToSuppliers < ActiveRecord::Migration
  def change
    add_column :suppliers, :cap_name, :string
  end
end
