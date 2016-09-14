#encoding: utf-8
class Train < ActiveRecord::Base
  has_many :train_staff_relations

  TYPE = {:NEW_STAFF => 0, :INCREASE => 1, :REEDUCATION => 2}
  TYPES_NAME = {0 => "新员工培训", 1 => "升职培训", 2 => "再教育培训"}
end
