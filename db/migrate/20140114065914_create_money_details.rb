class CreateMoneyDetails < ActiveRecord::Migration
  def change  #费用明细表
    create_table :money_details do |t|
      t.integer :types #类别
      t.integer :parent_id #费用或者资产id
      t.string :month #分摊月数
      t.timestamps
    end
    add_column :money_details, :amount, :"decimal(12,2)",:default=>0 #总金额
    add_index :money_details, :types
  end
end
