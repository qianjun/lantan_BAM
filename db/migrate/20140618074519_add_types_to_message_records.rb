class AddTypesToMessageRecords < ActiveRecord::Migration
  def change
    add_column :message_records, :types, :integer
    add_column :message_records, :total_fee,:decimal,{:precision=>"10,2",:default=>0}
    add_column :message_records, :total_num, :integer
    add_column :send_messages, :fee, :decimal,{:precision=>"5,2",:default=>0}
    add_column :send_messages, :is_paid, :boolean,:default=>0
  end
end
