#encoding:utf-8
require 'date'
require 'will_paginate/array'
class MaterialOrderManagesController < ApplicationController
  before_filter :sign?
  layout "complaint" 
  def index
    @store_id = params[:store_id].to_i
    @statistics_month = (params[:statistics_month] ||= Time.now.months_ago(1).strftime("%Y-%m"))
    @suppliers = Supplier.select("id,name").where(["store_id=? and status=?", @store_id, Supplier::STATUS[:normal]])
    @supplier_id = params[:supplier_id]
    m_sql = ["select sum(moi.price * moi.material_num) price,sum(moi.material_num) count,c.id,c.name
      from material_orders mo inner join mat_order_items moi on mo.id=moi.material_order_id
      inner join materials m on moi.material_id=m.id
      inner join categories c on m.category_id=c.id
      where mo.store_id=? and mo.m_status in (?) and mo.status in (?) and m.status=?
      and date_format(mo.created_at,'%Y-%m')=? and c.types=? and c.store_id=?",
      @store_id,[MaterialOrder::M_STATUS[:send],MaterialOrder::M_STATUS[:received],MaterialOrder::M_STATUS[:save_in]],
      [MaterialOrder::STATUS[:no_pay], MaterialOrder::STATUS[:pay]],Material::STATUS[:NORMAL],@statistics_month,
      Category::TYPES[:material], @store_id]
    s_sql = ["select mo.status,moi.price,moi.material_num
      from material_orders mo inner join mat_order_items moi on mo.id=moi.material_order_id
      inner join materials m on moi.material_id=m.id
      inner join categories c on m.category_id=c.id
      where mo.store_id=? and mo.m_status in (?) and mo.status in (?) and m.status=?
      and date_format(mo.created_at,'%Y-%m')=? and c.types=? and c.store_id=?",
      @store_id,[MaterialOrder::M_STATUS[:send],MaterialOrder::M_STATUS[:received],MaterialOrder::M_STATUS[:save_in]],
      [MaterialOrder::STATUS[:no_pay], MaterialOrder::STATUS[:pay]],Material::STATUS[:NORMAL],@statistics_month,
      Category::TYPES[:material], @store_id]
    if @supplier_id.nil? || @supplier_id.to_i==0
      m_sql[0] += " and mo.supplier_id=? and mo.supplier_type=?"
      m_sql << 0 << 0
      s_sql[0] += " and mo.supplier_id=? and mo.supplier_type=?"
      s_sql << 0 << 0
    else
      m_sql[0] += " and mo.supplier_id=? and mo.supplier_type=?"
      m_sql << @supplier_id.to_i << 1
      s_sql[0] += " and mo.supplier_id=? and mo.supplier_type=?"
      s_sql << @supplier_id.to_i << 1
    end
    m_sql[0] += " group by c.id order by sum(moi.price * moi.material_num) desc"
    @mat_orders = MaterialOrder.find_by_sql(m_sql)
    @t_price = @mat_orders.inject(0){|i,m|i += m.price.to_f;i} if @mat_orders.any?
    @t_count = @mat_orders.inject(0){|i,m|i += m.count.to_i;i} if @mat_orders.any?

    s_orders = MaterialOrder.find_by_sql(s_sql)
    @no_pay = 0
    @has_pay = 0
    s_orders.each do |s|
      if s.status.to_i == MaterialOrder::STATUS[:no_pay]
        @no_pay += s.price.to_f * s.material_num.to_i
      elsif s.status.to_i == MaterialOrder::STATUS[:pay]
        @has_pay += s.price.to_f * s.material_num.to_i
      end
    end if s_orders.any?
    
  end

  def flow_analysis #流量分析
    @store_id = params[:store_id].to_i
    @statistics_month = (params[:statistics_month] ||= Time.now.months_ago(1).strftime("%Y-%m"))
    mat_out_orders = MatOutOrder.find_by_sql(["select moo.material_num num,moo.price price,moo.types type,c.id cid,c.name cname
        from mat_out_orders moo inner join materials m on moo.material_id=m.id
        inner join categories c on m.category_id=c.id
        where moo.store_id=? and date_format(moo.created_at,'%Y-%m')=? and m.status=?",
        @store_id, @statistics_month, Material::STATUS[:NORMAL]])
    @total_count = mat_out_orders.length  #出库记录XXX条
    @total_price = mat_out_orders.inject(0){|i,m| i += m.num.to_i * m.price.to_f;i} if mat_out_orders.any?

    #库存类别表
    h_a = mat_out_orders.group_by{|m|m.cname} if mat_out_orders.any?
    arr = []
    @t_count = 0
    h_a.each do |k, v|
      hash = {}
      hash[:name] = k
      t_price = v.inject(0){|i,moo|i += moo.num.to_i * moo.price.to_f;i}
      t_count = v.inject(0){|i,moo|i += moo.num.to_i;i}
      @t_count += t_count
      hash[:price] = t_price
      hash[:count] = t_count
      arr << hash
    end if h_a
    @arr = arr.sort { |a, b| b[:price] <=> a[:price] } if arr.any?

    #出库性质表
    h_a2 = mat_out_orders.group_by{|m|m.type} if mat_out_orders.any?
    arr2 = []
    @t_count2 = 0
    h_a2.each do |k, v|
      hash = {}
      hash[:type] = k
      t_price = v.inject(0){|i,moo|i += moo.num.to_i * moo.price.to_f;i}
      t_count = v.inject(0){|i,moo|i += moo.num.to_i;i}
      @t_count2 += t_count
      hash[:price] = t_price
      hash[:count] = t_count
      arr2 << hash
    end if h_a2
    @arr2 = arr2.sort { |a, b| b[:price] <=> a[:price] } if arr2.any?
  end

  #库存结构分析
  def storage_analysis
    @store_id = params[:store_id].to_i
    @mat_list = Material.find_by_sql(["select sum(m.price * m.storage) price,sum(m.storage) count,c.name name
        from materials m inner join categories c on m.category_id=c.id
        where m.status=? and m.store_id=? group by c.id order by sum(m.price * m.storage) desc",
        Material::STATUS[:NORMAL], @store_id])
    @t_price = @mat_list.inject(0){|i,m| i += m.price.to_f;i} if @mat_list.any?
    @t_count = @mat_list.inject(0){|i,m| i += m.count.to_i;i} if @mat_list.any?

  end
end
