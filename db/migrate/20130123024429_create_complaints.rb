class CreateComplaints < ActiveRecord::Migration
  def change
    create_table :complaints do |t|
      t.integer :order_id
      t.text :reason
      t.text :suggestion
      t.text :remark
      t.boolean :status, :default => 0
      t.integer :types
      t.integer :staff_id_1  #投诉技师
      t.integer :staff_id_2
      t.datetime :process_at   #处理时间
      t.boolean :is_violation   #是否违规
      t.integer :customer_id
      t.integer :store_id

      t.timestamps
    end

    add_index :complaints, :order_id
    add_index :complaints, :types
    add_index :complaints, :staff_id_1
    add_index :complaints, :staff_id_2
    add_index :complaints, :customer_id
    add_index :complaints, :store_id
  end
end
