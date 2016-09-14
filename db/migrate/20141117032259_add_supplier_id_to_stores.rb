class AddSupplierIdToStores < ActiveRecord::Migration
  def change
    add_column :stores, :supplier_id, :integer
  end
end
