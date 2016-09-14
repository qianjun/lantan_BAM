#encoding: utf-8
class StaffRoleRelation < ActiveRecord::Base
  belongs_to :staff
  belongs_to  :role
end
