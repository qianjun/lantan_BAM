class ModifyStatusToCPcarRelations < ActiveRecord::Migration
  def change
    change_column :c_pcard_relations, :status, :integer
  end
end
