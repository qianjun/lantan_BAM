#encoding: utf-8
class DataManagesController < ApplicationController
  include MarketManagesHelper
  before_filter :sign?
  layout "complaint", :except => []
  require 'will_paginate/array'

  def index
    @f_num = Hash.new {|h,k|h[k]=[]}
    @t_orders,@t_num = [],[]
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "date_format(orders.created_at,'%Y-%m-%d') between '#{@start_time}' and '#{@end_time}'"
    orders = OrderPayType.joins(:order=>{:order_prod_relations=>{:product=>:category}}).select("pay_type,categories.types c_types,
    pay_type,categories.id c_id,orders.id o_id,round(ifnull(sum(order_pay_types.price),0),2) sum_price").where(:orders=>
        {:store_id=>params[:store_id],:status=>Order::PRINT_CASH}).where(sql).group("pay_type,c_id,o_id").group_by{|i|
      {:pay_type=>i.pay_type,:ca=>i.c_id}}
    @favour = orders.select{|k,v| OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,fav| h[fav.c_id] ||= 0; h[fav.c_id] +=fav.sum_price;@f_num[fav.c_id]<<fav.o_id;h}
    @prod_service = orders.reject{|k,v| OrderPayType::FAVOUR.include? k[:pay_type] }.values.flatten.inject({}){
      |h,p|@t_orders << p.o_id;h[p.c_types] ||= {}; h[p.c_types][p.c_id]||=0; h[p.c_types][p.c_id] +=p.sum_price;h}
    @category = Category.where(:store_id=>params[:store_id],:types=>Category::DATA_TYPES).inject({}){|h,c|h[c.types] ||= {}; h[c.types][c.id]=c.name;h}
    @favour_cat = @category.values.flatten.inject({}){|h,v|h.merge!(v)}
    @t_price = Order.joins(:order_prod_relations=>{:product=>:category}).select("round(sum(order_prod_relations.t_price),2) sum_t,
      categories.types c_types,categories.id c_id,count(*) num").group("c_types,c_id").where(:"orders.id"=>@t_orders.compact.uniq).
      inject({}){|h,o| @t_num[o.c_types] ||={};h[o.c_types] ||= {};h[o.c_types][o.c_id]=o.sum_t;@t_num[o.c_types][o.c_id]=o.num;h} #计算成本价
    @total_t_price = @t_price.values.flatten.inject({}){|h,v|h.merge!(v)}.values.compact.reduce(:+)
    @total_price = @prod_service.values.flatten.inject({}){|h,v|h.merge!(v)}.values.compact.reduce(:+)
    respond_to do |format|
      format.html
      format.js
    end
  end

  def ajax_prod_serv
    category_id = params[:category_id].to_i
    sql = "date_format(orders.created_at,'%Y-%m-%d') between '#{params[:first_time]}' and '#{params[:last_time]}'"
    if params[:is_pcard] && params[:is_pcard].to_i == 1
      sql += " and orders.c_pcard_relation_id is not null "
    else
       sql += " and orders.c_pcard_relation_id is null "
    end
    if params[:c_types].to_i == 0 or params[:c_types].to_i == 3
      sql += " and category_id=#{category_id}"
    elsif params[:c_types].to_i == 1 or params[:c_types].to_i == 2
      sql += " and categories.types=#{category_id}"
    end
    if params[:c_types].to_i < 3
      @c_name = params[:c_types].to_i == 0 ? Category.find(category_id).name : Category::TYPES_NAME[category_id]
      @orders = Order.joins(:order_prod_relations=>{:product=>:category}).select("ifnull(sum(order_prod_relations.pro_num),0) pro_num,
    ifnull(sum(order_prod_relations.total_price),0) total_price,round(ifnull(sum(order_prod_relations.t_price),0),2) t_price,products.id p_id,
    date_format(orders.created_at,'%Y-%m-%d') day,ifnull(sum(order_prod_relations.total_price-order_prod_relations.t_price),0) earn_price,
    products.service_code,products.name,orders.c_pcard_relation_id").where(:"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH).where(sql).group("p_id,day").group_by{|i|i.day}
    else
      @c_name = params[:c_types].to_i == 3 ? Category.find(category_id).name : "折扣优惠"
      @orders = OrderPayType.joins({:product=>:category},:order).select("'--' pro_num,ifnull(sum(order_pay_types.price),0) total_price,
    date_format(orders.created_at,'%Y-%m-%d') day,'--' t_price,products.id p_id,ifnull(sum(order_pay_types.price),0) earn_price,
    products.service_code,products.name").where(:"orders.store_id"=>params[:store_id],:"orders.status"=>Order::PRINT_CASH,
        :"pay_type"=>OrderPayType::FAVOUR).where(sql).group("p_id,day").group_by{|i|i.day}
    end
  end
end
