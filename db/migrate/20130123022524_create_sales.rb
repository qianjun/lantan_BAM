class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.string :name
      t.datetime :started_at  
      t.datetime :ended_at
      t.text :introduction
      t.integer :disc_types   #打折方式
      t.integer :status
      t.float :discount    #折扣
      t.integer :store_id
      t.integer :disc_time_types  #打折时间方式
      t.integer :car_num           #折扣数量
      t.integer :everycar_times   #每辆车的打折次数
      t.string :img_url
      t.boolean :is_subsidy
      t.string :sub_content
      t.string :code
      t.string :description

      t.timestamps
    end

    add_index :sales, :status
    add_index :sales, :store_id
    add_index :sales, :created_at
    add_index :sales, :code
  end
end
