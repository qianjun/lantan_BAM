#encoding: utf-8
require 'date'
class MaterialOrder < ActiveRecord::Base
  include ApplicationHelper

  has_many :mat_order_items
  has_many :mat_out_orders
  has_many  :mat_in_orders
  has_many  :m_order_types
  has_many :materials, :through => :mat_order_items
  belongs_to :supplier

  STATUS = {:no_pay => 0, :pay => 1, :cancel => 4}
  S_STATUS = { 0 => "未付款", 1 => "已付款", 4 => "已取消"}
  M_STATUS = {:no_send => 0, :send => 1, :received => 2, :save_in => 3, :returned => 4} #0未发货，1已发货，2已收货，3已入库，4已退货
  S_M_STATUS = { 0 => "未发货", 1 => "已发货", 2 => "已收货", 3 => "已入库", 4 => "已退货"}
  PAY_TYPES = {:CHARGE => 1, :SAV_CARD => 2, :CASH => 3, :STORE_CARD => 4, :SALE_CARD => 5}
  PAY_TYPE_NAME = {1 => "支付宝",2 => "储值卡", 3 => "现金", 4 => "门店账户扣款", 5 => "活动优惠"}

  def self.make_order
    status = 0

    status
  end

  def self.set_code(len)
    chars =  (0..9).to_a
    code_array = []
    1.upto(len) {code_array << chars[rand(chars.length)]}
    return code_array.join("")
  end

  def self.material_order_code(store_id, time=nil)
    (time.nil? ? Time.now.strftime("%Y%m%d%H%M%S") : DateTime.parse(time).strftime("%Y%m%d%H%M%S"))+set_code(3)
  end

  #  def self.supplier_order_records page, per_page, store_id
  #    self.paginate(:select => "*", :from => "material_orders", :include => [:supplier, {:mat_order_items => :material}], :conditions => "material_orders.supplier_id != 0 and material_orders.store_id = #{store_id}",
  #      :order => "material_orders.created_at desc",:page => page, :per_page => per_page)
  #  end

  #   def self.head_order_records page, per_page, store_id, status=nil
  #     sql = status.nil? ? "" : "and material_orders.m_status=#{status}"
  #     self.paginate(:select => "*", :from => "material_orders", :include => [:mat_order_items => :material],
  #       :conditions => "material_orders.supplier_id = 0 #{sql} and material_orders.store_id = #{store_id}",
  #       :order => "material_orders.created_at desc",:page => page, :per_page => per_page)
  #   end
  def self.material_order_list store_id, status=nil,m_status=nil,from_date=nil,to_date=nil,supplier_id=nil
    sql = ["select mo.* from material_orders mo where mo.store_id=?", store_id]
    unless status.nil? || status==-1
      sql[0] += " and mo.status=?"
      sql << status
    end
    unless m_status.nil? || m_status==-1
      sql[0] += " and mo.m_status=?"
      sql << m_status
    end
    unless from_date.nil? || from_date.empty?
      sql[0] += " and date_format(mo.created_at,'%Y-%m-%d')>=?"
      sql << from_date
    end
    unless to_date.nil? || to_date.empty?
      sql[0] += " and date_format(mo.created_at,'%Y-%m-%d')<=?"
      sql << to_date
    end
    if supplier_id.nil?
      sql[0] += " and mo.supplier_id!=0"
    else
      sql[0] += " and mo.supplier_id=?"
      sql << supplier_id
    end
    sql[0] += " order by mo.created_at desc"
    records = MaterialOrder.find_by_sql(sql)
    arr = []
    total_money = 0
    pay_money = 0
    records.each do |r|
      total_money += r.price.to_f
      if r.status==MaterialOrder::STATUS[:pay]
        pay_money +=  r.price.to_f
      end
    end
    total_count = records.length
    arr << records << total_money << pay_money << total_count
    return arr
  end
  #    def self.search_orders store_id,from_date, to_date, status, supplier_id,page,per_page,m_status
  #      str = "mo.store_id = #{store_id} "
  #      if supplier_id == 0
  #       str += " and mo.supplier_id = 0 "
  #     else
  #       str += " and mo.supplier_id != 0 "
  #      end
  #      if status
  #        if status == 0
  #          str += " and mo.status=#{STATUS[:no_pay]} "
  #       elsif status == 1
  #         str += " and mo.status=#{STATUS[:pay]} "
  #       end
  #      end
  #      if m_status
  #        if m_status == 0
  #         str += " and mo.m_status=#{M_STATUS[:no_send]} "
  #       elsif m_status == 1
  #         str += " and mo.m_status=#{M_STATUS[:send]} "
  #       elsif m_status == 2
  #          str += " and mo.m_status=#{M_STATUS[:received]} "
  #       elsif m_status == 3
  #         str += " and mo.m_status=#{M_STATUS[:save_in]} "
  #       end
  #      end
  #      if from_date && from_date.length > 0
  #        str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) >= unix_timestamp(date_format('#{from_date}','%Y-%m-%d')) "
  #      end
  #      if to_date && to_date.length > 0
  #        str += " and unix_timestamp(date_format(mo.created_at,'%Y-%m-%d')) <= unix_timestamp(date_format('#{to_date}','%Y-%m-%d')) "
  #     end
  #      orders = self.paginate(:select => "mo.*", :from => "material_orders mo", :conditions => str,
  #        :order => "created_at desc",
  #        :page => page, :per_page => per_page)
  #     orders
  #    end

  def check_material_order_status
    mo_status = []
    self.mat_order_items.group_by{|moi| moi.material_id}.each do |material_id, value|
      mat_order_item = MatOrderItem.find_by_material_id_and_material_order_id(material_id, self.id)
      mat_in_order = MatInOrder.where(:material_id => material_id, :material_order_id => self.id)
      if !mat_in_order.nil?
        if mat_in_order.sum(:material_num) >= mat_order_item.try(:material_num)
          mo_status << true
        else
          mo_status << false
        end
      else
        mo_status << false
      end
    end
    !mo_status.include?(false)
  end

  def transfer_status
    case self.m_status
    when M_STATUS[:no_send]
      "未发货"
    when M_STATUS[:send]
      "已发货"
    when M_STATUS[:received]
      "已收货"
    when M_STATUS[:save_in]
      "已入库"
    when M_STATUS[:returned]
      "已退货"
    else
      "未知"
    end
  end

  def pay_status
    case self.status
    when STATUS[:no_pay]
      "未付款"
    when STATUS[:pay]
      "已付款"
    when STATUS[:cancel]
      "已取消"
    else
      "未知"
    end
  end

  def supplier_name
    if supplier_type==0
      "总部"
    else
      supplier.name
    end
  end

  def svc_use_price
    MOrderType.find_by_material_order_id_and_pay_types(self.id, PAY_TYPES[:SAV_CARD]).try(:price)
  end

  def sale_price
    if self.sale_id && self.sale_id!=0
      sale = Sale.find self.sale_id
      sale.sub_content
    end
  end

  def pay_type_name
    mot = MOrderType.where("material_order_id = ? and pay_types not in (?)", self.id, [2,5]).first
    PAY_TYPE_NAME[mot.pay_types] unless mot.nil?
  end
end
