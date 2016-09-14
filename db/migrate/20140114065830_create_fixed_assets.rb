class CreateFixedAssets < ActiveRecord::Migration
def change  #固定资产表
    create_table :fixed_assets do |t|
      t.string :code  #订单号
      t.string :name  #资产名称
      t.datetime :fee_date #发生日期
      t.integer :types #资产类别
      t.datetime :pay_date #支付日期
      t.integer :num #数量
      t.integer :share_month #分摊月数
      t.integer :payment_type #支付类型
      t.string :remark
      t.integer :status,:default=>0
      t.integer :operate_staffid #经办人
      t.integer :create_staffid  #创建人
      t.timestamps
    end
    add_column :fixed_assets, :price, :"decimal(12,2)",:default=>0 #单价
    add_column :fixed_assets, :amount, :"decimal(12,2)",:default=>0 #总金额
    add_column :fixed_assets, :pay_amount, :"decimal(12,2)",:default=>0 #总金额
    add_index :fixed_assets, :types
     add_index :fixed_assets, :status
  end
end
