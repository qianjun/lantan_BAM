#encoding: utf-8
class FixedAsset < ActiveRecord::Base
  STATUS =  ApplicationHelper::MODEL_STATUS.merge({:INVALID =>2}) #0 正常 1 删除 2 作废
  STATUS_NAMES = {0=>"正常",1=>"删除",2=>"报废"}
end
