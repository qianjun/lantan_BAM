class AddLockToStations < ActiveRecord::Migration
  def change
    add_column :stations, :locked, :boolean,:default=>0
  end
end
