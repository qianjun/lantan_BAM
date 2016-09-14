class CreateSharedMaterials < ActiveRecord::Migration
  def change
    #创建公共的物料表，给各个门店共用物料 条形码、名称、类型， 规格
    create_table :shared_materials do |t|
      t.string :code
      t.string :name
      t.integer :types, :limit => 1
      t.string :unit

      t.timestamps
    end
  end
end
