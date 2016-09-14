class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.decimal :base_price,:default=>0,:precision=>"20,2"
      t.decimal :sale_price,:default=>0,:precision=>"20,2"  #销售价格
      t.string :description   #产品介绍
      t.integer :types  #清洁类，保养类。。。
      t.string :service_code   #服务代码
      t.boolean :status     #状态
      t.text :introduction
      t.boolean :is_service   #判断是产品还是服务
      t.integer :staff_level   #所需技师等级
      t.integer :staff_level_1  
      t.string :img_url
      t.integer :cost_time   #花费时长
      t.integer :store_id
      t.string :standard #规格
      t.integer  :single_types,:defalut=>0
      t.decimal  :techin_price,:default=>0,:precision=>"20,2"
      t.decimal  :techin_percent,:default=>0,:precision=>"20,2"
      t.boolean :is_added, :default=>0
      t.integer :category_id
      t.boolean :commonly_used,  :default => false  #给服务加标志，服务是否在新的下单系统中显示
      t.decimal :deduct_price,:default=>0,:precision=>"20,2"
      t.boolean  :show_on_ipad,  :default => true #判断服务是否在ipad端显示
      t.integer  :prod_point,:default=>0
      t.boolean  :is_auto_revist
      t.integer  :auto_time
      t.text     :revist_content
      t.decimal   :t_price,:default=>0,:precision=>"20,2"
      t.decimal :deduct_percent,:default=>0,:precision=>"20,2"
      t.timestamps
    end

    add_index :products, :name
    add_index :products, :types
    add_index :products, :status
    add_index :products, :is_service
    add_index :products, :store_id
  end
end
