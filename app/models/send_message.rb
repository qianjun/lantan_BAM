#encoding: utf-8
class SendMessage < ActiveRecord::Base
  belongs_to :message_record
  belongs_to :customer
  belongs_to :store
  STATUS = {:WAITING =>0,:FINISHED =>1,:IGNORE =>2,:FAIL =>3}  #0 未发送 1 已发送 2 已忽略 3 发送失败
  TYPES = {:OTHER =>0,:REVIST =>1,:WARN =>2} # 0 其他信息 1 回访 2 提醒
  SATS_NAMES = {0=> "等待发送",1=>"已发送",2=>"已忽略",3=>"发送失败"}
  TYPES_NAMES = {0=> "其他信息",1=>"回访信息",2=>"提醒信息"}
end
