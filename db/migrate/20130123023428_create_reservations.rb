class CreateReservations < ActiveRecord::Migration
  #预约表
  def change
    create_table :reservations do |t|
      t.integer :car_num_id
      t.datetime :res_time  #预约时间 年月日 小时 分钟 
      t.integer :status   #预约状态
      t.integer :store_id

      t.datetime :created_at
    end

    add_index :reservations, :car_num_id
    add_index :reservations, :status
    add_index :reservations, :store_id
    add_index :reservations, :created_at
  end
end
