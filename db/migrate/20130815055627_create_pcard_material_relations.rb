class CreatePcardMaterialRelations < ActiveRecord::Migration
  def change
    create_table :pcard_material_relations do |t|
      t.integer :material_id
      t.integer :material_num
      t.integer :package_card_id
      t.timestamps
    end
    add_index :pcard_material_relations,:material_id
    add_index :pcard_material_relations,:package_card_id
  end
end
