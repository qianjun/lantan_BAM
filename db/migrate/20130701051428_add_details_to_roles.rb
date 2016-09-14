class AddDetailsToRoles< ActiveRecord::Migration
  def change
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
  end
end
