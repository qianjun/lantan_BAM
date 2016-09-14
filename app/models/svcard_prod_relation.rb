#encoding: utf-8
class SvcardProdRelation < ActiveRecord::Base
  belongs_to :product
  belongs_to :sv_card
end
