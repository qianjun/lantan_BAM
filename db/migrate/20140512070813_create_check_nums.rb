class CreateCheckNums < ActiveRecord::Migration
  def change
    create_table :check_nums do |t|
      t.integer :total_num
      t.string :file_name
      t.integer :store_id
      t.timestamps
    end
  end
end
