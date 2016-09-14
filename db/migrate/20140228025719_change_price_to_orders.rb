class ChangePriceToOrders < ActiveRecord::Migration
  change_column :sv_cards, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :order_pay_types, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :orders, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :orders, :front_deduct, :decimal,{:precision=>"20,2",:default=>0}
  change_column :orders, :technician_deduct, :decimal,{:precision=>"20,2",:default=>0}
  change_column :m_order_types, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :materials, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :material_orders, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :c_svc_relations, :total_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :c_svc_relations, :left_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :t_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :techin_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :techin_percent, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :sale_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :deduct_percent, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :deduct_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :base_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :products, :prod_point,:integer,:default=>0
  change_column :package_cards, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :package_cards, :deduct_percent, :decimal,{:precision=>"20,2",:default=>0}
  change_column :package_cards, :deduct_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :order_prod_relations, :price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :order_prod_relations, :t_price, :decimal,{:precision=>"20,2",:default=>0}
  change_column :order_prod_relations, :total_price, :decimal,{:precision=>"20,2",:default=>0}
end
