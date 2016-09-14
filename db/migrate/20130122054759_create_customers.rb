class CreateCustomers < ActiveRecord::Migration
  def change
    create_table :customers do |t|
      t.string :name
      t.string :mobilephone
      t.string :other_way  #其他联系方式
      t.boolean :sex, :default => 1
      t.datetime :birthday
      t.string :address
      t.boolean :is_vip, :default => 0
      t.string :mark  
      t.boolean :status, :default => 0
      t.integer :types
      t.integer :store_id
      t.integer :total_point, :default => 0
      t.string :openid
      t.string :encrypted_password
      t.string :username
      t.string :salt
      t.integer :property, :default => 0  #客户属性 个人/集团客户
      t.integer :allowed_debts, :default => 0  #是否允许欠账
      t.integer :debts_money #欠账额度
      t.string :group_name #集团名称(如果是集团客户)
      t.integer :check_type  #结算类型(月/周)
      t.integer :check_time #结算时间(..月/..周)



      t.timestamps
    end

    add_index :customers, :name
    add_index :customers, :mobilephone
    add_index :customers, :birthday
    add_index :customers, :is_vip
    add_index :customers, :status
    add_index :customers, :types
    add_index :customers, :username
  end
end
