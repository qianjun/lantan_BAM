class CreateRevisits < ActiveRecord::Migration
#  回访表
  def change
    create_table :revisits do |t|
      t.integer :customer_id
      t.integer :types
      t.string :title  #投诉标题
      t.string :answer  #投诉回答
      t.integer :complaint_id   #投诉编号
      t.text :content  #投诉内容

      t.timestamps
    end

    add_index :revisits, :customer_id
    add_index :revisits, :types
    add_index :revisits, :title
    add_index :revisits, :complaint_id
  end
end
