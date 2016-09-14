class AddDetailsToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :reward_fee, :float,:default=>0
    add_column :salaries, :secure_fee, :float,:default=>0
    add_column :salaries, :voilate_fee, :float,:default=>0
  end
end
