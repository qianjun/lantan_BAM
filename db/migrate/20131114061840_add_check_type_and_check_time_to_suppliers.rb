class AddCheckTypeAndCheckTimeToSuppliers < ActiveRecord::Migration
  def change
    add_column :suppliers, :check_type, :integer
    add_column :suppliers, :check_time, :integer
  end
end
