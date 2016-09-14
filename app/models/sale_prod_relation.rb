#encoding: utf-8
class SaleProdRelation < ActiveRecord::Base
 belongs_to :sale
 belongs_to  :product
end
