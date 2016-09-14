class AddTrainTypeToTrains < ActiveRecord::Migration
  def change
    add_column :trains, :train_type, :integer
  end
end
