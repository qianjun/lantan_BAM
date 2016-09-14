#encoding: utf-8
class MOrderType < ActiveRecord::Base
  belongs_to :material_order
end
