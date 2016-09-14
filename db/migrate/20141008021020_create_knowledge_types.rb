class CreateKnowledgeTypes < ActiveRecord::Migration
  def change
    create_table :knowledge_types do |t|
      t.string :name
      t.integer :store_id

      t.timestamps
    end
  end
end
