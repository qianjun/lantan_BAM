class AddStaffIdToPayReceipts < ActiveRecord::Migration
  def change
    add_column :pay_receipts, :staff_id, :integer
  end
end
