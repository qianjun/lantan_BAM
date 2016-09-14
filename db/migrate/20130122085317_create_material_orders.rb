class CreateMaterialOrders < ActiveRecord::Migration
  #物料订购
  def change
    create_table :material_orders do |t|
      t.string :code    #订单号
      t.integer :supplier_id  #供货商编号
      t.integer :supplier_type  #供货类型
      t.integer :status      #
      t.integer :staff_id
      t.float :price
      t.datetime :arrival_at   #到达日期
      t.string :logistics_code  #物流单号
      t.string :carrier     #托运人姓名
      t.integer :store_id
      t.string :remark
      t.integer :sale_id #活动代码对应的活动
      t.integer :m_status #物流订单状态

      t.timestamps
    end

    add_index :material_orders, :code
    add_index :material_orders, :supplier_id
    add_index :material_orders, :supplier_type
    add_index :material_orders, :status
    add_index :material_orders, :staff_id
    add_index :material_orders, :store_id
    add_index :material_orders, :sale_id
    add_index :material_orders, :m_status
  end
end
