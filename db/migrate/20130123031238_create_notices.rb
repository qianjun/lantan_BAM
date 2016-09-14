class CreateNotices < ActiveRecord::Migration
  #消息提醒
  def change
    create_table :notices do |t|
      t.integer :target_id   #相关订单
      t.integer :types
      t.text :content
      t.boolean :status
      t.integer :store_id

      t.datetime :created_at
    end

    add_index :notices, :store_id
    add_index :notices, :status
    add_index :notices, :types
  end
end
