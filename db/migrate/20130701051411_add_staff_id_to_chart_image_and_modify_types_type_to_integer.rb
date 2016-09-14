class AddStaffIdToChartImageAndModifyTypesTypeToInteger < ActiveRecord::Migration
  def change
    add_column :chart_images, :staff_id, :integer
    change_column :chart_images, :types, :integer
  end
end
