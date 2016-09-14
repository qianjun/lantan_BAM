#encoding: utf-8
class RoleMenuRelation < ActiveRecord::Base
 belongs_to :role
 belongs_to :menu
end
