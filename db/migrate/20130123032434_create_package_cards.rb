class CreatePackageCards < ActiveRecord::Migration
  #套餐卡
  def change
    create_table :package_cards do |t|
      t.string :name
      t.string :img_url
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :store_id
      t.boolean :status
      t.decimal :price,:precision=>"20,2",:default=>0
      t.integer :date_types,:default=>0
      t.integer :date_month
      t.boolean :is_auto_revist
      t.integer :auto_time
      t.text :revist_content
      t.integer :prod_point,:default=>0
      t.string :description
      t.decimal :deduct_price,:precision=>"20,2",:default=>0
      t.decimal :deduct_percent,:precision=>"20,2",:default=>0
      t.decimal :sale_percent,:precision=>"20,16",:default=>1
      t.boolean :auto_warn,:default=>0
      t.integer :time_warn
      t.string :con_warn

      t.timestamps
    end

    add_index :package_cards, :store_id
    add_index :package_cards, :status
    add_index :package_cards, :created_at
    add_index :package_cards, :updated_at
  end
end
