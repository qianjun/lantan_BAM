class CreateTrains < ActiveRecord::Migration
  def change
    create_table :trains do |t|
      t.string :content
      t.datetime :start_at
      t.datetime :end_at
      t.boolean :certificate #是否有证书

      t.datetime :created_at
    end
  end
end
