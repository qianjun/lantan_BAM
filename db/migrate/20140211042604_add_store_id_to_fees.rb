class AddStoreIdToFees < ActiveRecord::Migration
  def change
    add_column :fees, :store_id, :integer
    add_column :fixed_assets, :store_id, :integer
    add_column :money_details, :store_id, :integer
    add_column :pay_receipts, :store_id, :integer
    add_column :accounts, :store_id, :integer
    add_column :history_accounts, :store_id, :integer
  end
end
