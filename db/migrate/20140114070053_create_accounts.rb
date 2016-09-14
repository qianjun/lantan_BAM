class CreateAccounts < ActiveRecord::Migration
  def change  #往来账户表
    create_table :accounts do |t|
      t.integer :types #类别
      t.integer :supply_id #供应商活客户单位id
      t.timestamps
    end
    add_column :accounts, :left_amt, :"decimal(12,2)",:default=>0 #之前剩余未付金额
    add_column :accounts, :trade_amt, :"decimal(12,2)",:default=>0 #本期交易发生金额
    add_column :accounts, :pay_recieve, :"decimal(12,2)",:default=>0 #本期收到支付余额
    add_column :accounts, :balance, :"decimal(12,2)",:default=>0 #余额
    add_index :accounts, :types
  end
end
