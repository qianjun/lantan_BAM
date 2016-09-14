class CreateSendMessages < ActiveRecord::Migration
  #信息发送表
  def change
    create_table :send_messages do |t|
      t.integer :message_record_id  #发送的消息
      t.text :content
      t.integer :customer_id   #指定客户
      t.string :phone
      t.datetime :send_at
      t.boolean :status

    end

    add_index :send_messages, :message_record_id
    add_index :send_messages, :status
  end
end
