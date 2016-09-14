#encoding: utf-8
class AlipayRecord < ActiveRecord::Base
  belongs_to :store
  
  STATUS = {:NORMAL =>0,:FAIL =>1} #充值成功 1 失败
  STAT_NAME = {0=>"充值成功",1=>"充值失败"}
end
