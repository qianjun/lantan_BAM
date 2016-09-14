#encoding: utf-8
class AddCollectCodeToStationdata < ActiveRecord::Migration
  def change
    add_column :stations, :collector_code, :string  #采集器编号
  end
end
