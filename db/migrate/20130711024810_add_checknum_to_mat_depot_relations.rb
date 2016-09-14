class AddChecknumToMatDepotRelations < ActiveRecord::Migration
  def change
    add_column :mat_depot_relations, :check_num, :integer
  end
end
