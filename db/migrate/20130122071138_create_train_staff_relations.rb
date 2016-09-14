class CreateTrainStaffRelations < ActiveRecord::Migration
  def change
    create_table :train_staff_relations do |t|
      t.integer :train_id
      t.integer :staff_id
      t.boolean :status

    end

    add_index :train_staff_relations, :train_id
    add_index :train_staff_relations, :staff_id
    add_index :train_staff_relations, :status
  end
end
