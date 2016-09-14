class CreateWOTimes < ActiveRecord::Migration
  #工位排单
  def change
    create_table :wk_or_times do |t|
      t.string :current_times  #当天时间  小时分钟
      t.integer :current_day   #年月日
      t.integer :station_id   #工单编号
      t.integer :worked_num   #已工作次数
      t.integer :wait_num     #目前等待数量

      t.datetime :created_at
    end

    add_index :wk_or_times, :current_day
    add_index :wk_or_times, :station_id
  end
end
