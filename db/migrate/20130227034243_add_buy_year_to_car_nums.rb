class AddBuyYearToCarNums < ActiveRecord::Migration
  def change
    add_column :car_nums, :buy_year, :integer
  end
end
