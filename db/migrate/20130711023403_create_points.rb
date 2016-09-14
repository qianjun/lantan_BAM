class CreatePoints < ActiveRecord::Migration
  def change  #积分表
    create_table :points do |t|
      t.integer :customer_id
      t.integer :target_id
      t.integer :point_num
      t.string  :target_content
      t.integer :types
      t.timestamps
    end
    add_index :points,:customer_id
    add_index :points,:target_id
  end
end
