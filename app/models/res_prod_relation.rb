#encoding: utf-8
class ResProdRelation < ActiveRecord::Base
  belongs_to :product
  belongs_to :reservation
end
