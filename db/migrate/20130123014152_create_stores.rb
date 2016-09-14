class CreateStores < ActiveRecord::Migration
  #门店表
  def change
    create_table :stores do |t|
      t.string :name
      t.string :address
      t.string :phone
      t.string :contact   #门店联系人
      t.string :email
      t.string :position   #门店坐标
      t.string :introduction #门店介绍
      t.string :img_url
      t.datetime :opened_at
      t.float :account  #门店账户余额
      t.decimal :close_reason
      t.integer :city_id
      t.integer :status
      t.integer :material_low #设置该门店的库存数量预警值，当低于该值时，显示缺货警告
      t.string :code
      t.integer :edition_lv
      t.string :limited_password
      t.string :cash_auth, :default => 0
      t.string :auto_send,:default=>1
      t.boolean :is_chain
      t.decimal :message_fee,:precision=>"10,2",:default=>0
      t.boolean :owe_warn
      t.string :send_list

      t.timestamps
    end

    add_index :stores, :created_at
    add_index :stores, :city_id
    add_index :stores, :status
    add_index :stores, :edition_lv
  end
end
