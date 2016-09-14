class CreateCustomerNumRelations < ActiveRecord::Migration
  def change
    create_table :customer_num_relations do |t|
      t.integer :customer_id
      t.integer :car_num_id
    end

    add_index :customer_num_relations, :customer_id
    add_index :customer_num_relations, :car_num_id
  end
end
