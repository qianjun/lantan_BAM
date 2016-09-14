class AddStationCodeToStations < ActiveRecord::Migration
  def change
    add_column :stations, :code, :string    #添加采集器编号字段
  end
end
