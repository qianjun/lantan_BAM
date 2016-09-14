class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string :code     #订单流水号
      t.integer :car_num_id  #车牌
      t.integer :status
      t.datetime :started_at
      t.datetime :ended_at
      t.decimal :price,:precision=>"20,2",:default=>0
      t.boolean :is_visited  #是否回访
      t.integer :is_pleased  #是否满意
      t.boolean :is_billing  #是否要发票
      t.integer :front_staff_id  #前台
      t.integer :cons_staff_id_1  #施工甲编号
      t.integer :cons_staff_id_2  #施工乙编号
      t.integer :station_id      #工位编号
      t.integer :sale_id         #参加活动
      t.integer :c_pcard_relation_id  #套餐卡
      t.integer :c_svc_relation_id    #优惠卡
      t.boolean :is_free      #是否免单
      t.integer :types    
      t.integer :store_id
      t.datetime :warn_time
      t.integer :sale_id
      t.integer :c_pcard_relation_id
      t.integer :c_svc_relation_id
      t.datetime :auto_time
      t.string :qfpos_id
      t.integer :customer_id
      t.decimal :front_deduct,:precision=>"20,2",:default=>0
      t.decimal :technician_deduct,:precision=>"20,2",:default=>0
      t.timestamps
    end

    add_index :orders, :code
    add_index :orders, :car_num_id
    add_index :orders, :status
    add_index :orders, :created_at
    add_index :orders, :price
    add_index :orders, :front_staff_id
    add_index :orders, :cons_staff_id_1
    add_index :orders, :cons_staff_id_2
    add_index :orders, :station_id
    add_index :orders, :sale_id
    add_index :orders, :c_pcard_relation_id
    add_index :orders, :c_svc_relation_id
    add_index :orders, :store_id
    add_index :orders, :types
    add_index :orders, :is_visited
    add_index :orders, :customer_id
  end
end
