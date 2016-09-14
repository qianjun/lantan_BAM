class CreateBackGoodRecords < ActiveRecord::Migration
  def change
    create_table :back_good_records do |t|
      t.integer :material_id
      t.integer :material_num
      t.integer :supplier_id
      t.timestamps
    end
    add_index :back_good_records, :material_id
  end
end
