#encoding: utf-8
class MessageRecord < ActiveRecord::Base
  has_many :send_messages
  belongs_to :store

  STATUS = {:NORMAL => 0, :SENDED => 1,:IGNORE => 2} # 0 未发送 1 已发送 2 已忽略

  SET_MESSAGE = {0=>"储值卡购买提醒",1=>"储值卡使用提醒",2=>"储值卡修改密码",3=>"储值卡退卡提醒",
    4=>"退单到储值卡",5=>"套餐卡购买提醒",6=>"套餐卡使用提醒",7=>"退单到套餐卡",8=>"套餐卡退卡提醒",9=>"自动回访/提醒",
    11=>"修改登录密码",12=>"短信群发",13=>"单客户信息",14=>"添加员工",15=>"客户生日提醒",16=>"微信验证码"}
  M_TYPES = {:BUY_SV =>0,:USE_SV =>1,:CHANGE_SV =>2,:RETURN_SV =>3,:BACK_SV =>4,:BUY_PCARD =>5,:USE_PCARD =>6,:RETURN_PCARD =>7,:BACK_PCARD =>8,
    :AUTO_REVIST =>9,:AUTO_WARN =>10,:CHANGE_PWD =>11,:PACK_MSG =>12,:SINGLE_MSG =>13,:ADD_STAFF =>14,:BIRTH_WARN =>15,:WECHAT => 16 }


  PAY_TYPES = {:ALIPAY => 1,:LICENSE=>2 } #0  支付宝
  PAY_NAME = {1 =>"支付宝充值"}

  def self.send_code order_id,phone
    order = Order.find_by_id order_id
    status = 0
    if order && order.customer.mobilephone == phone
      self.create(:content => "订单：#{order.code},储值卡支付的验证码为：123456", :store_id => order.store_id, :status => STATUS[:NORMAL])
      status = 1
    end
    status
  end
  
end
