class AddBaseSalaryToSalaries < ActiveRecord::Migration
  def change
    add_column :salaries, :base_salary, :float,:default=>0
  end
end
