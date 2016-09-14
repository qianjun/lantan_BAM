class AddReturnTypesToOrderProdRelations < ActiveRecord::Migration
  def change
    add_column :c_pcard_relations, :return_types, :integer,:default=>0
    add_column :c_svc_relations, :return_types, :integer,:default=>0
    add_column :orders, :return_types, :integer,:default=>0
    add_column :orders, :return_direct, :integer
    add_column :orders, :return_fee, :float,:default =>0
    add_column :orders, :return_staff_id,:integer
     add_column :orders, :return_reason, :integer
  end
end
