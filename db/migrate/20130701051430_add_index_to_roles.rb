class AddIndexToRoles< ActiveRecord::Migration
  def change
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
  end
end
