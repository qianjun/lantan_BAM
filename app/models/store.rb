#encoding: utf-8
class Store < ActiveRecord::Base
  require 'mini_magick'
  include ApplicationHelper
  has_many :stations
  has_many :reservations
  has_many :products
  has_many :sales
  has_many :work_orders
  has_many :svc_return_records
  has_many :goal_sales
  has_many :message_records
  has_many :notices
  has_many :package_cards
  has_many :staffs
  has_many :materials
  has_many :suppliers
  has_many :month_scores
  has_many :complaints
  has_many :sv_cards
  has_many :store_chain_relations
  has_many :depots
  has_many :customers
  has_many  :alipay_records
  belongs_to :city
  has_many :roles

  AUTO_SEND = {:YES =>1,:NO =>0}  #是否自动发送 1 自动发送 0 不自动发送
  STATUS = {
    :CLOSED => 0,       #0该门店已关闭，1正常营业，2装修中, 3已删除
    :OPENED => 1,
    :DECORATED => 2,
    :DELETED => 3
  }
  S_STATUS = {
    0 => "已关闭",
    1 => "正常营业",
    2 => "装修中",
    3 => "已删除"
  }
  EDITION_LV ={       #门店使用的系统的版本等级
    0 => "实用版",
    1 => "精英版",
    2 => "豪华版",
    3 => "旗舰版"
  }
  EDITION_NAME = {:FACTUARL => 0} # 使用版  0
  IS_CHAIN = {:YES => 1,:NO => 0} #是否有关联的连锁店

  CASH_AUTH = {:NO => 0, :YES => 1} #是否有在pad上收银的权限

  def warn_store(this_price)
    store_parm = {:message_fee=>self.message_fee-this_price}
    if self.message_fee < this_price and !self.owe_warn
      warn_message = "您的#{self.name}短信费用已不足，余额为#{(self.message_fee-this_price).round(2)}，为保证系统功能的正常使用请充值。"
      m_arr = [{:content =>URI.escape(warn_message), :msid => "#{self.id}", :mobile => self.phone.strip}]
      send_message_request(m_arr,1)
      store_parm.merge!({:owe_warn=>Constant::OWE_WARN[:DONE]})
    end
    if self.message_fee - this_price < 5 and self.message_fee >=5
      content = "您系统的信息费用余额已不足5元，为保证系统功能的正常使用，请<a href='/stores/#{self.id}/messages/send_alipay' target='_blank'>充值</a>"
      Log.create(:show_index=>0,:store_types=>self.id,:roll=>1,:status=>1,:title=>"您的信息费用余额已不足5元,为保证功能正常使用请充值。",:content=>content)
    end
    self.update_attributes(store_parm)
  end

end
