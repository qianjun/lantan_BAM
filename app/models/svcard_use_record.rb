#encoding: utf-8
class SvcardUseRecord < ActiveRecord::Base
  belongs_to :c_svc_relation

  TYPES = {:IN => 0, :OUT => 1} 
end
