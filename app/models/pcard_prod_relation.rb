#encoding: utf-8
class PcardProdRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :product
end
