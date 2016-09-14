class UpdateIncrements < ActiveRecord::Migration
  def up
    num = 1
    execute "alter table car_nums auto_increment=#{num}"
    execute "alter table revisits auto_increment=#{num}"
    execute "alter table c_svc_relations auto_increment=#{num}"
    execute "alter table customers auto_increment=#{num}"
    execute "alter table revisit_order_relations auto_increment=#{num}"
    execute "alter table staffs auto_increment=#{num}"
    execute "alter table trains auto_increment=#{num}"
    execute "alter table salaries auto_increment=#{num}"
    execute "alter table work_records auto_increment=#{num}"
    execute "alter table salary_details auto_increment=#{num}"
    execute "alter table train_staff_relations auto_increment=#{num}"
    execute "alter table violation_rewards auto_increment=#{num}"
    execute "alter table month_scores auto_increment=#{num}"
    execute "alter table staff_gr_records auto_increment=#{num}"
    execute "alter table car_brands auto_increment=#{num}"
    execute "alter table car_models auto_increment=#{num}"
    execute "alter table customer_num_relations auto_increment=#{num}"
    execute "alter table stations auto_increment=#{num}"
    execute "alter table station_staff_relations auto_increment=#{num}"
    execute "alter table station_service_relations auto_increment=#{num}"
    execute "alter table work_orders auto_increment=#{num}"
    execute "alter table wk_or_times auto_increment=#{num}"
    execute "alter table order_pay_types auto_increment=#{num}"
    execute "alter table orders auto_increment=#{num}"
    execute "alter table order_prod_relations auto_increment=#{num}"
    execute "alter table m_order_types auto_increment=#{num}"
    execute "alter table materials auto_increment=#{num}"
    execute "alter table material_orders auto_increment=#{num}"
    execute "alter table prod_mat_relations auto_increment=#{num}"
    execute "alter table mat_order_items auto_increment=#{num}"
    execute "alter table mat_in_orders auto_increment=#{num}"
    execute "alter table mat_out_orders auto_increment=#{num}"
    execute "alter table suppliers auto_increment=#{num}"
    execute "alter table stores auto_increment=#{num}"
    execute "alter table products auto_increment=#{num}"
    execute "alter table sales auto_increment=#{num}"
    execute "alter table sale_prod_relations auto_increment=#{num}"
    execute "alter table reservations auto_increment=#{num}"
    execute "alter table menus auto_increment=#{num}"
    execute "alter table res_prod_relations auto_increment=#{num}"
    execute "alter table role_menu_relations auto_increment=#{num}"
    execute "alter table complaints auto_increment=#{num}"
    execute "alter table roles auto_increment=#{num}"
    execute "alter table staff_role_relations auto_increment=#{num}"
    execute "alter table role_model_relations auto_increment=#{num}"
    execute "alter table message_records auto_increment=#{num}"
    execute "alter table send_messages auto_increment=#{num}"
    execute "alter table goal_sales auto_increment=#{num}"
    execute "alter table notices auto_increment=#{num}"
    execute "alter table news auto_increment=#{num}"
    execute "alter table package_cards auto_increment=#{num}"
    execute "alter table sv_cards auto_increment=#{num}"
    execute "alter table pcard_prod_relations auto_increment=#{num}"
    execute "alter table c_pcard_relations auto_increment=#{num}"
    execute "alter table svcard_use_records auto_increment=#{num}"
    execute "alter table svcard_prod_relations auto_increment=#{num}"
    execute "alter table svc_return_records auto_increment=#{num}"
    execute "alter table capitals auto_increment=#{num}"
    execute "alter table cities auto_increment=#{num}"
    execute "alter table image_urls auto_increment=#{num}"
    execute "alter table goal_sale_types auto_increment=#{num}"
    execute "alter table chart_images auto_increment=#{num}"
  end

  def down
  end
end