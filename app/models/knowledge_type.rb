#encoding: utf-8
class KnowledgeType < ActiveRecord::Base
  TYPES = ["保养知识","汽车知识","案例分享"]
  
  def self.import_types(store_id)
    knows = self.where(:store_id=>store_id)
    TYPES.map{ |name|knows << self.create(:name=>name,:store_id=>store_id)} if knows.blank?
    knows
  end
end
