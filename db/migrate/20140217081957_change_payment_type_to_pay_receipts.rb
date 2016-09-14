class ChangePaymentTypeToPayReceipts < ActiveRecord::Migration
  rename_column :pay_receipts, :payment_type, :category_id
end