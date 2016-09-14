class AddStaffIdToChains < ActiveRecord::Migration
  def change
    add_column :chains, :staff_id, :integer
    add_index :chains, :staff_id
  end
end
