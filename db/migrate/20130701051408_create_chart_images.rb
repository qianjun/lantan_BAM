class CreateChartImages < ActiveRecord::Migration
  def change
    create_table :chart_images,:options => 'AUTO_INCREMENT = 1001' do |t|
      t.integer :id
      t.integer :store_id
      t.string :image_url
      t.string :types
      t.datetime :created_at
    end
    add_index :chart_images, :store_id
    add_index :chart_images, :created_at
    add_index :chart_images, :types
  end
  
end
