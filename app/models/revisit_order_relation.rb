#encoding: utf-8
class RevisitOrderRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :revisit
end
