#encoding: utf-8
class Supplier < ActiveRecord::Base
  has_many :material_orders
  has_many :back_good_records
  TYPES = {:head => 0,:branch => 1}
  STATUS = {:normal => 0, :delete => 1}
  CHECK_TYPE = {:MONTH => 1, :DAY => 2}   #结算方式 1按月结算 2日结算
  S_CHECK_TYPE = {1 => "按月结算", 2 => "按日结算"}
end
