class CreateTechOrders < ActiveRecord::Migration
  def change
    create_table :tech_orders do |t|
      t.integer :staff_id
      t.integer :order_id
      t.decimal :own_deduct,{:precision=>"20,2",:default=>0}

      t.timestamps
    end
  end
end
