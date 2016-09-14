class CreatePayReceipts < ActiveRecord::Migration
  def change  #收款/付款单
    create_table :pay_receipts do |t|
      t.integer :types #类别
      t.integer :supply_id #供应商活客户单位id
      t.string :month #收款类型月份 例201401
      t.integer :payment_type #支付类型
      t.timestamps
    end
    add_column :pay_receipts, :amount, :"decimal(12,2)",:default=>0 #总金额
    add_index :pay_receipts, :types
    add_index :pay_receipts, :payment_type
  end
end
