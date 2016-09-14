#encoding: utf-8
class Chain < ActiveRecord::Base
  has_many :store_chain_relations
  STATUS = {
    :DELETED => 0,    #已关闭
    :NORMAL => 1     #正常
  }
  S_STATUS = {
    0 => "已关闭",
    1 => "正常运营"
  }
end
