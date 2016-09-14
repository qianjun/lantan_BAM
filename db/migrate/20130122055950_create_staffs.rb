class CreateStaffs < ActiveRecord::Migration
  #员工表
  def change
    create_table :staffs do |t|
      t.string :name
      t.integer :type_of_w   #职务
      t.integer :position    #岗位
      t.boolean :sex
      t.integer :level       #等级
      t.datetime :birthday
      t.string :id_card      #身份证
      t.string :hometown
      t.integer :education
      t.string :nation
      t.string :political
      t.string :phone
      t.string :address
      t.string :photo
      t.float :base_salary
      t.integer :deduct_at   #提成开始数量
      t.integer :deduct_end  #提成结束数量
      t.float :deduct_percent
      t.integer :status, :default => 0
      t.integer :store_id
      t.string :encrypted_password
      t.string :username
      t.string :salt
      t.boolean :is_score_ge_salary, :default => false
      t.integer :status, :limit => 1  #员工状态
      t.integer :working_stats #在职状态 0试用 1正式
      t.decimal :probation_salary,:precision=>"20,2",:default=>0  #试用薪资
      t.boolean :is_deduct #是否提成
      t.integer :probation_days  #试用期(天)
      t.string :validate_code
      t.integer :department_id
      t.decimal :secure_fee,:precision=>"20,2",:default=>0
      t.decimal :reward_fee,:precision=>"20,2",:default=>0
      t.datetime :last_login
      t.timestamps
    end

    add_index :staffs, :name
    add_index :staffs, :status
    add_index :staffs, :store_id
    add_index :staffs, :level
    add_index :staffs, :type_of_w
    add_index :staffs, :position
    add_index :staffs, :username
  end
end
