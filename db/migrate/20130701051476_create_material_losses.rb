class CreateMaterialLosses < ActiveRecord::Migration
  def change
    create_table :material_losses do |t|
      t.string :code #条形码
      t.string :name #物料名称
      t.integer :types #物料类别
      t.integer :loss_num #报损数量
      t.string :specifications #规格
      t.float :price  #成本价
      t.float :sale_price    #零售价
      t.integer :staff_id #报损人
      t.integer :store_id  #所属门店

      t.timestamps
    end
    add_index :material_losses, :staff_id
  end
end
