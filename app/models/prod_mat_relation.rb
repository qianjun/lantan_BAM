#encoding: utf-8
class ProdMatRelation < ActiveRecord::Base
  belongs_to :material
  belongs_to :product
end
