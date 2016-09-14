class AddTypesToPaymentDefines < ActiveRecord::Migration
  def change
    add_column :payment_defines, :types, :integer
    rename_column :payment_defines,:description,:name
  end
end
