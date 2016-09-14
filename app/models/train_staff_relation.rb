#encoding: utf-8
class TrainStaffRelation < ActiveRecord::Base
  belongs_to :train
  belongs_to :staff
end
