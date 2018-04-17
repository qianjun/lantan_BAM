class ChangeNameWithSalaryDetailsTable < ActiveRecord::Migration
  def up
    rename_column :salary_details, :voilation_reward_id, :violation_reward_id
    add_column :stations, :name, :string
    add_column :sv_cards, :description, :string
    add_column :svcard_prod_relations, :base_price, :float
    add_column :svcard_prod_relations, :more_price, :float
    add_column :trains, :train_type, :integer
    add_column :c_pcard_relations, :price, :float

    remove_column :goal_sales, :goal_price
    remove_column :goal_sales, :type_name
    remove_column :goal_sales, :current_price

    add_column :chart_images, :current_day, :datetime
    add_index :chart_images, :current_day
    add_column :chart_images, :staff_id, :integer
    change_column :chart_images, :types, :integer
    
    add_column :violation_rewards, :score_num, :float #按分值算
    add_column :violation_rewards, :salary_num, :float #按金额算
    
    add_column :violation_rewards, :process_at, :datetime
    remove_column :salary_details, :violation_reward_id

    add_column :svcard_use_records, :content, :string

    add_column :capitals, :created_at, :datetime
    add_column :car_brands, :created_at, :datetime
    add_column :car_models, :created_at, :datetime
    add_column :car_nums, :created_at, :datetime
    add_column :customer_num_relations, :created_at, :datetime
    add_column :goal_sale_types, :created_at, :datetime
    add_column :image_urls, :created_at, :datetime
    add_column :m_order_types, :created_at, :datetime
    add_column :menus, :created_at, :datetime
    add_column :order_prod_relations, :created_at, :datetime
    add_column :pcard_prod_relations, :created_at, :datetime
    add_column :prod_mat_relations, :created_at, :datetime
    add_column :res_prod_relations, :created_at, :datetime
    add_column :revisit_order_relations, :created_at, :datetime
    add_column :role_menu_relations, :created_at, :datetime
    add_column :role_model_relations, :created_at, :datetime
    add_column :roles, :created_at, :datetime
    add_column :sale_prod_relations, :created_at, :datetime
    add_column :send_messages, :created_at, :datetime
    add_column :staff_role_relations, :created_at, :datetime
    add_column :svcard_prod_relations, :created_at, :datetime
    add_column :train_staff_relations, :created_at, :datetime

    add_index :capitals, :created_at
    add_index :car_brands, :created_at
    add_index :car_models, :created_at
    add_index :car_nums, :created_at
    add_index :cities, :created_at
    add_index :customer_num_relations, :created_at
    add_index :goal_sale_types, :created_at
    add_index :image_urls, :created_at
    add_index :m_order_types, :created_at
    add_index :mat_order_items, :created_at
    add_index :menus, :created_at
    add_index :order_pay_types, :created_at
    add_index :order_prod_relations, :created_at
    add_index :pcard_prod_relations, :created_at
    add_index :prod_mat_relations, :created_at
    add_index :res_prod_relations, :created_at
    add_index :revisit_order_relations, :created_at
    add_index :role_menu_relations, :created_at
    add_index :role_model_relations, :created_at
    add_index :roles, :created_at
    add_index :sale_prod_relations, :created_at
    add_index :send_messages, :created_at
    add_index :staff_role_relations, :created_at
    add_index :svcard_prod_relations, :created_at
    add_index :train_staff_relations, :created_at

    add_column :stations, :collector_code, :string  #采集器编号

    add_column :c_pcard_relations, :order_id, :integer
    add_index :c_pcard_relations, :order_id
    change_column :work_orders,:water_num,:float
	change_column :work_orders,:electricity_num,:float
	change_column :work_orders,:violation_num,:float
	change_column :work_orders,:runtime,:float
	change_column :work_records,:water_num,:float
	change_column :work_records,:elec_num,:float
	change_column :work_records,:violation_num,:float

	add_column :stations, :elec_switch, :string #工位配电开关
    add_column :stations, :clean_m_fb, :string #清洗机反馈
    add_column :stations, :gas_t_switch, :string #气体流量开关
    add_column :stations, :gas_run_fb, :string #空气机运行反馈
    add_column :stations, :gas_error_fb, :string #空气机故障反馈
    add_column :stations, :system_error, :string #系统报警
    add_column :stations, :is_using, :string #工位有效占用
    add_column :stations, :day_hmi, :string #工位日hmi复位
    add_column :stations, :month_hmi, :string #工位月hmi复位
    add_column :stations, :once_gas_use, :string #工位一次使用的气体数量
    add_column :stations, :once_water_use, :string #工位一次使用的水数量
    add_column :work_orders, :gas_num, :float

    change_column :salary_details,:deduct_num,:float
    change_column :salary_details,:reward_num,:float
    change_column :salaries,:deduct_num,:float
    change_column :salaries,:reward_num,:float

    add_column :o_pcard_relations, :created_at, :datetime
    add_column :o_pcard_relations, :updated_at, :datetime
    add_column :month_scores, :store_id, :integer
    add_column :complaints, :c_feedback_suggestion, :boolean #客户反馈意见
    change_column :staffs, :status, :integer, :limit => 1  #员工状态

    add_column :staff_gr_records, :working_stats, :integer    #在职状态 0试用 1正式

    add_column :sv_cards, :store_id, :integer
    add_column :sv_cards, :use_range, :integer    #优惠卡使用范围
    add_column :sv_cards, :status, :integer, :default => 1
    add_column :work_records, :gas_num, :float
    remove_column :equipment_infos, :station_id
    remove_column :equipment_infos, :water_num
    remove_column :equipment_infos, :gas_num
    remove_column :equipment_infos, :status
    add_column :equipment_infos, :current_day, :integer
    add_column :equipment_infos, :num, :integer
    add_column :work_records, :store_id, :integer  #添加工作记录的所属门店

    add_column :work_orders, :cost_time, :integer
    add_column :stations, :is_has_controller, :boolean

    add_column :role_model_relations, :model_name, :string

    add_column :mat_depot_relations, :check_num, :integer

    add_column :role_menu_relations, :store_id, :integer

    add_column :roles, :store_id, :integer
    add_column :roles, :role_type, :integer

    add_column :role_model_relations, :store_id, :integer

    add_column :car_nums, :buy_year, :integer

    add_column :salaries, :status, :boolean, :default => 0
    add_index :salaries, :status

    add_column :stations, :staff_level, :integer
    add_column :stations, :staff_level1, :integer

    add_column :chains, :staff_id, :integer
    add_index :chains, :staff_id

    add_column :station_staff_relations, :store_id, :integer
    add_index :station_staff_relations, :store_id

    add_column :mat_out_orders, :store_id, :integer

    remove_column :material_losses, :code
    remove_column :material_losses, :name
    remove_column :material_losses, :types
    remove_column :material_losses, :specifications
    remove_column :material_losses, :price
    remove_column :material_losses, :sale_price
    add_column :material_losses, :material_id, :integer
    add_index :material_losses, :material_id

    add_column :customer_store_relations,:total_point,:integer
    add_column :customer_store_relations,:is_vip,:boolean, :default => 0

    add_column :equipment_infos, :station_id, :integer
  end

  def down
  end
end
