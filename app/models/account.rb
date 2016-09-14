#encoding: utf-8
class Account < ActiveRecord::Base
  TYPES = {:CUSTOMER => 0,:SUPPLY =>1} #0 客户 1 供应商
  TYPES_NAMES = {0=>"应收",1=>"应付"} #客户的为应收  供应商的为应付
end
