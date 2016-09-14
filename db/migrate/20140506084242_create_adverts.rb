class CreateAdverts < ActiveRecord::Migration
  def change
    create_table :adverts do |t|
      t.string :content
      t.integer :last_time
      t.integer :store_id
      t.timestamps
    end
  end
end
