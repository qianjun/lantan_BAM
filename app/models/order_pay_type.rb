#encoding: utf-8
class OrderPayType < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  PAY_TYPES = {:CASH => 0, :CREDIT_CARD => 1, :SV_CARD => 2, 
    :PACJAGE_CARD => 3, :SALE => 4, :IS_FREE => 5, :DISCOUNT_CARD => 6,:FAVOUR =>7,:CLEAR =>8,:HANG =>9} #0 现金  1 刷卡  2 储值卡   3 套餐卡  4  活动优惠  5免单
  PAY_TYPES_NAME = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 4 => "活动优惠", 5 => "免单", 6 => "打折卡",7=>"优惠",8=>"抹零",9=>"挂账"}
  LOSS = [PAY_TYPES[:SALE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  PAY_STATUS = {:UNCOMPLETE =>1,:COMPLETE =>0} #1 挂账未结账  0  已结账
  PAY_NAME = {0=>"已付",1=>"未付"}
  FAVOUR = [PAY_TYPES[:SALE],PAY_TYPES[:IS_FREE],PAY_TYPES[:DISCOUNT_CARD],PAY_TYPES[:FAVOUR],PAY_TYPES[:CLEAR]]
  FINCANCE_TYPES = {0 => "现金", 1 => "银行卡", 2 => "储值卡", 3 => "套餐卡", 5 => "免单", 6 => "打折卡",9=>"挂账"}
  OTHER_TYPES = {2 => "储值卡",3=> "套餐卡"}

  
  def self.order_pay_types(orders)
    return OrderPayType.find(:all, :conditions => ["order_id in (?)", orders]).inject(Hash.new){|hash,t|
      hash[t.order_id].nil? ? hash[t.order_id] = [t.pay_type ==PAY_TYPES[:HANG] ? PAY_TYPES_NAME[t.pay_type]+"(#{PAY_NAME[t.pay_status]})" : PAY_TYPES_NAME[t.pay_type]] : hash[t.order_id] << (t.pay_type ==PAY_TYPES[:HANG] ? PAY_TYPES_NAME[t.pay_type]+"(#{PAY_NAME[t.pay_status]})" : PAY_TYPES_NAME[t.pay_type]);
      hash[t.order_id]=hash[t.order_id].uniq;hash}
  end

  def self.search_pay_order(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,order_id").where(:order_id=>orders).group('order_id').inject(Hash.new){
      |hash,o| hash[o.order_id]=o.sum;hash}
  end

  def self.search_pay_types(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,pay_type").where(:order_id=>orders).group('pay_type').inject(Hash.new){
      |hash,o|hash[o.pay_type]=o.sum;hash}
  end

  def self.pay_order_types(orders)
    OrderPayType.select(" ifnull(sum(price),0) sum,order_id,pay_type").where(:order_id=>orders).group('order_id,pay_type').inject(Hash.new){
      |hash,o| hash[o.order_id].nil? ? hash[o.order_id]={o.pay_type=>o.sum} : hash[o.order_id][o.pay_type]=o.sum;hash}
  end

  def self.customer_pay_types(orders)
    OrderPayType.joins(:order).select(" ifnull(sum(order_pay_types.price),0) sum,pay_type,customer_id c_id ").where(:order_id=>orders).group('c_id,pay_type').inject(Hash.new){
      |hash,o|hash[o.c_id].nil? ?  hash[o.c_id]={o.pay_type=>o.sum} : hash[o.c_id][o.pay_type]=o.sum ;hash}
  end
  
end
