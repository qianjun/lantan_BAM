class AddTypesToResvations < ActiveRecord::Migration
  def change
    add_column :reservations, :types, :integer #区别是意向单还是预约单
    add_column :reservations, :prod_types, :integer #区分项目是产品 套擦卡 打折卡 储值卡等
    add_column :reservations, :prod_id, :integer   #项目id
    add_column :reservations, :prod_price, :decimal,:precision=>"20,2",:default=>0  #项目价格  包括意向单价
    add_column :reservations, :prod_num, :integer   #项目数量
    add_column :reservations, :deduct_num, :decimal,:precision=>"5,2",:default=>0  #提成价格
    add_column :reservations, :staff_id, :integer   #意向单洽谈人
    add_column :reservations, :order_id, :integer   #意向单转成的订单的id
    add_column :reservations, :code, :string   #单号
    add_column :reservations, :customer_id, :integer   #客户编号
  end
end
