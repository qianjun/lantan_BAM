class CustomerStoreRelation < ActiveRecord::Base
  belongs_to :customer
  belongs_to :store

  IS_VIP = {:NO => 0, :YES => 1}    #是否是会员
end
