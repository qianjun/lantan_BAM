class CreateFees < ActiveRecord::Migration
 def change  #费用
    create_table :fees do |t|
      t.string :code  #订单号
      t.string :name  #费用名称
      t.datetime :fee_date #发生日期
      t.integer :types #费用类别
      t.datetime :pay_date #支付日期
      t.integer :payment_type #支付方式
      t.integer :share_month #分摊月数
      t.string :remark
      t.integer :status,:default=>0
      t.integer :operate_staffid #经办人
      t.integer :create_staffid  #创建人
      t.timestamps
    end
    add_column :fees, :amount, :"decimal(12,2)",:default=>0 #金额
    add_index :fees, :types
  end
end
