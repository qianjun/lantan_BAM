class AddStatusToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :status, :boolean, :default => 0
    add_index :salaries, :status
  end
end
