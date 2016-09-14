class ChangeStatusToSendMessage < ActiveRecord::Migration
  change_column :send_messages, :status, :integer,:default=>1
  add_column :send_messages, :car_num_id, :integer
  add_column :send_messages, :types, :integer,:default=>0
  add_column :send_messages, :store_id, :integer
end
