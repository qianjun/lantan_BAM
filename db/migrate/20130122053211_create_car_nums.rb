class CreateCarNums < ActiveRecord::Migration
  def change
    create_table :car_nums do |t|
      t.string :num
      t.integer :car_model_id
    end

    add_index :car_nums, :num
    add_index :car_nums, :car_model_id
  end
end
