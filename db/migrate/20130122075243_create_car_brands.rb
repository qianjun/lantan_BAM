class CreateCarBrands < ActiveRecord::Migration
  #汽车品牌表
  def change
    create_table :car_brands do |t|
      t.string :name
      t.integer :capital_id
    end

    add_index :car_brands, :name
    add_index :car_brands, :capital_id
  end
end
