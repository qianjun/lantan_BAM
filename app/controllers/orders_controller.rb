#encoding: utf-8
class OrdersController < ApplicationController
  before_filter :sign?
  
  def order_info
    @order = Order.joins(:customer).joins("left join work_orders w on w.order_id=orders.id left join stations s on s.id=w.station_id
    left join car_nums c on c.id=orders.car_num_id").select("orders.*,s.name s_name,c.num c_num,customers.name c_name,
    customers.mobilephone phone,customers.group_name,w.status w_status,return_types").where(:orders=>{:id=>params[:id]}).first
    @pay_types = OrderPayType.search_pay_types(params[:id])
    @order_prods = OrderProdRelation.order_products(params[:id])
    @tech_orders = TechOrder.where(:order_id=>params[:id]).group_by{|i|i.order_id}
    staff_ids = ([@order.front_staff_id]|@tech_orders.values.flatten.map(&:staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @tech_orders.each{|order_id,tech_orders| @tech_orders[order_id] = tech_orders.map{|tech|@staffs[tech.staff_id]}.join("、")}
    @return_orders = @order.return_orders
  end

  def order_staff
    ids = params[:id].split("_")
    @complaint_id = ids[0]
    @comp_page = params[:comp_page].empty? ? 1 : params[:comp_page]
    @order = Order.one_order_info(ids[1].to_i)
    @tech_orders = TechOrder.joins(:staff).where(:order_id=>@order.id).select("staffs.name s_name,staff_id")
    respond_to do |format|
      format.js
    end
  end
end
