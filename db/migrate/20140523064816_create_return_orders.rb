class CreateReturnOrders < ActiveRecord::Migration
  def change
    create_table :return_orders do |t|
      t.integer :order_id #订单id
      t.integer :return_type  #退单方式
      t.decimal :return_price,:default=>0,:precision=>"20,2" #实际退款金额
      t.decimal :abled_price,:default=>0,:precision=>"20,2" #可退款金额
      t.string  :order_code #退单编号
      t.integer :pro_num  #当前退单的数量
      t.integer :pro_types #退单类别 产品服务/套餐卡/储值卡 0 是产品 1 是服务 2 是套餐卡 3 是打折卡 4 是储值卡
      t.integer :return_direct #产品报废还是回库
      t.integer :store_id
      t.timestamps
    end
  end
end
