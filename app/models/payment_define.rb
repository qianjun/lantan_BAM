#encoding: utf-8
class PaymentDefine < ActiveRecord::Base
  STATUS = {:NORMAL =>0,:DELETE=>1} #付款类型的状态
end
