class CreateMessageRecords < ActiveRecord::Migration
  #信息记录
  def change
    create_table :message_records do |t|
      t.text :content
      t.datetime :send_at
      t.boolean :status, :default => 0
      t.integer :store_id
      t.datetime :created_at
    end

    add_index :message_records, :store_id
    add_index :message_records, :status
  end
end
