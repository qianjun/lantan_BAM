class ChangeTypeToSalaries < ActiveRecord::Migration
  change_column :salaries, :deduct_num, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :reward_num, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :total, :decimal,{:precision=>"20.2",:default=>0}
  change_column :salaries, :reward_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :secure_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :voilate_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :fact_fee, :decimal,{:precision=>"20.2",:default=>0}
  change_column :salaries, :work_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :manage_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :tax_fee, :decimal,{:precision=>"20,2",:default=>0}
  change_column :salaries, :base_salary, :decimal,{:precision=>"20.2",:default=>0}
  change_column :staffs, :secure_fee, :decimal,{:precision=>"20.2",:default=>0}
  change_column :staffs, :reward_fee, :decimal,{:precision=>"20.2",:default=>0}
end
