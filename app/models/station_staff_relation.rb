#encoding: utf-8
class StationStaffRelation < ActiveRecord::Base
  belongs_to :station
  belongs_to :staff

  scope :this_store,lambda{|store_id|where(:store_id=>store_id)}
   
  def self.load_relation(store_id,station_ids)
    self.where(:store_id => store_id,:station_id => station_ids)
  end
end
