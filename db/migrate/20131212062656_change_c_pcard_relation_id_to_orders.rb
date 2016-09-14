class ChangeCPcardRelationIdToOrders < ActiveRecord::Migration
  def change
    change_column :orders, :sale_id, :string
    change_column :orders, :c_pcard_relation_id, :string
    change_column :orders, :c_svc_relation_id, :string
  end
end
