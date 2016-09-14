class CreateCPcardRelations < ActiveRecord::Migration
  #客户套餐卡表
  def change
    create_table :c_pcard_relations do |t|
      t.integer :customer_id
      t.integer :package_card_id
      t.datetime :ended_at
      t.boolean :status
      t.string :content

      t.datetime :created_at
    end

    add_index :c_pcard_relations, :customer_id
    add_index :c_pcard_relations, :package_card_id
    add_index :c_pcard_relations, :status
  end
end
