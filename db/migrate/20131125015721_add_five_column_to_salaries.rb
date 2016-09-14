class AddFiveColumnToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :fact_fee, :float,:default=>0
    add_column :salaries, :work_fee, :float,:default=>0
    add_column :salaries, :manage_fee, :float,:default=>0
    add_column :salaries, :tax_fee, :float,:default=>0
    add_column :salaries, :is_edited, :boolean,:defalut=>false
  end
end
