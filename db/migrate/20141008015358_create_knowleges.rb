class CreateKnowleges < ActiveRecord::Migration
  def change
    create_table :knowleges do |t|
      t.string :title
      t.integer :knowledge_type_id
      t.string :description
      t.text  :content
      t.string :img_url
      t.integer :store_id
      t.boolean :on_weixin,:default=>0

      t.timestamps
    end
  end
end
