class AddCurrentDayToChartImages < ActiveRecord::Migration
  def change
    add_column :chart_images, :current_day, :datetime

    add_index :chart_images, :current_day
  end
end
