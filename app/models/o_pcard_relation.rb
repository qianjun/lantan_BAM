#encoding: utf-8
class OPcardRelation < ActiveRecord::Base
  belongs_to :product
  belongs_to :order
end
