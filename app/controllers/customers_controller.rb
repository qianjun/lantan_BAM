#encoding: utf-8
require "uri"
class CustomersController < ApplicationController
  before_filter :sign?
  include RemotePaginateHelper
  layout "customer", :except => [:print_orders,:operate_order]
  require 'will_paginate/array'
  before_filter :customer_tips, :except => [:get_car_brands]

  def index
    @store = Store.find_by_id(params[:store_id]) || not_found
    @customers = Customer.search_customer(params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone],  params[:store_id].to_i)
    @t_customers = {}
    @customers.group_by{|i|i.property}.sort.reverse.each{|cu|@t_customers[cu[0]]=cu[1].paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)}
    vip_customer = @customers.group_by{|i|i.show_vip}
    pcard_customers = CPcardRelation.joins(:package_card).where(:status=>CPcardRelation::STATUS[:NORMAL],
      :"package_cards.store_id"=>@store.id).map(&:customer_id).compact.uniq
    save_customers = CSvcRelation.joins(:sv_card).where(:sv_cards=>{:store_id=>@store.id,:types=>SvCard::FAVOR[:SAVE]},
      :status=>CSvcRelation::STATUS[:valid]).map(&:customer_id).compact.uniq
    pcard,sv_card =[],[]
    @customers.each {|customer|
      pcard  << customer if pcard_customers.include?(customer.id)
      sv_card << customer if save_customers.include?(customer.id)
    }
    @t_customers[Customer::LIST_NAME[:PCARD]] = pcard.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) unless pcard.blank?
    @t_customers[Customer::LIST_NAME[:SV_CARD]] = sv_card.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) unless sv_card.blank?
    @t_customers[Customer::LIST_NAME[:VIP]] = vip_customer[true].paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) if vip_customer[true]
    @car_nums = Customer.customer_car_num(@customers)
  end

  def search
    @store = Store.find_by_id(params[:store_id]) || not_found
    @customers = Customer.search_customer(params[:car_num], params[:started_at], params[:ended_at],
      params[:name], params[:phone], params[:store_id].to_i)
    @car_nums = Customer.customer_car_num(@customers)
    @t_customers, pcard,sv_card ={},[],[]
    if  params[:types].to_i == Customer::LIST_NAME[:GROUP] || params[:types].to_i == Customer::LIST_NAME[:PERSONAL]
      customers = @customers.group_by{|i|i.property}
      @t_customers[params[:types].to_i] = customers[params[:types].to_i].paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) if customers[params[:types].to_i]
    elsif params[:types].to_i == Customer::LIST_NAME[:PCARD] #套餐卡用户的翻页
      pcard_customers = CPcardRelation.joins(:package_card).where(:status=>CPcardRelation::STATUS[:NORMAL],
        :"package_cards.store_id"=>@store.id).map(&:customer_id).compact.uniq
      @customers.each {|customer| pcard  << customer if pcard_customers.include?(customer.id) }
      @t_customers[Customer::LIST_NAME[:PCARD]] = pcard.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) unless pcard.blank?
    elsif params[:types].to_i == Customer::LIST_NAME[:SV_CARD]
      save_customers = CSvcRelation.joins(:sv_card).where(:sv_cards=>{:store_id=>@store.id,:types=>SvCard::FAVOR[:SAVE]},
        :status=>CSvcRelation::STATUS[:valid]).map(&:customer_id).compact.uniq
      @customers.each {|customer| sv_card << customer if save_customers.include?(customer.id)}
      @t_customers[Customer::LIST_NAME[:SV_CARD]] = sv_card.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) unless sv_card.blank?
    elsif params[:types].to_i == Customer::LIST_NAME[:VIP]
      vip_customer = @customers.group_by{|i|i.show_vip}
      @t_customers[Customer::LIST_NAME[:VIP]] = vip_customer[true].paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE) if vip_customer[true]
    end

  end


  def destroy
    customer = Customer.find(params[:id].to_i)
    hang_orders = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
      :orders=>{:store_id=>params[:store_id],:customer_id=>customer.id}).count
    if hang_orders >= 1
      flash[:notice] = "该客户有挂账未结清，删除失败。"
    else
      customer.update_attributes(:status => Customer::STATUS[:DELETED])
      flash[:notice] = "删除成功。"
    end
    redirect_to request.referer
  end

  def create
    if params[:new_name] and params[:mobilephone]
      customer = Customer.where(:status=>Customer::STATUS[:NOMAL],:mobilephone=>params[:mobilephone].strip,
        :store_id=>params[:store_id].to_i).first
      customer_num_relation = []
      if customer
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
        unless params[:selected_cars].blank?
          params[:selected_cars].each do |sc|
            car_num = sc.split("-")[0]
            car_model = sc.split("-")[1].to_i
            buy_year = sc.split("-")[2].to_i
            car_num_record = CarNum.where(:num=>car_num).first
            if car_num_record
              cnr = CustomerNumRelation.find_by_car_num_id_and_customer_id(car_num_record.id, customer.id)
              if cnr.nil?
                customer_num_relation << CustomerNumRelation.new(:car_num_id => car_num_record.id, :customer_id => customer.id)
              end
            else
              car_num_record = CarNum.create(:num => car_num, :buy_year => buy_year, :car_model_id => car_model)
              customer_num_relation << CustomerNumRelation.new(:car_num_id => car_num_record.id, :customer_id => customer.id)
            end
          end
        end
      else
        property = params[:property].to_i
        name = params[:new_name].strip
        group_name = params[:group_name].nil? ? nil : params[:group_name].strip
        allowed_debts = params[:allowed_debts].to_i
        debts_money = params[:debts_money].nil? ? nil : params[:debts_money].to_f
        check_type = params[:check_type].nil? ? nil : params[:check_type].to_i
        check_time = params[:check_time_month].nil? ? (params[:check_time_week].nil? ? nil : params[:check_time_week].to_i) : params[:check_time_month].to_i
        new_customer = Customer.create(:name => name, :mobilephone => params[:mobilephone].strip, :other_way => params[:other_way].strip,
          :sex => params[:sex], :birthday => params[:birthday].strip, :address => params[:address].strip,
          :status => Customer::STATUS[:NOMAL], :types => Customer::TYPES[:NORMAL], :username => name, :property => property,
          :group_name => group_name, :allowed_debts => allowed_debts, :debts_money => debts_money, :check_type => check_type,
          :check_time => check_time,:store_id=>params[:store_id],:is_vip => params[:is_vip],:show_vip=>params[:show_vip])
        new_customer.encrypt_password
        new_customer.save
        unless params[:selected_cars].blank?
          params[:selected_cars].each do |sc|
            car_num = sc.split("-")[0]
            car_model = sc.split("-")[1].to_i
            buy_year = sc.split("-")[2].to_i
            car_num_record = CarNum.where(:num=>car_num).first
            if car_num_record
              CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => new_customer.id)
            else
              car_num_record = CarNum.create(:num => car_num, :buy_year => buy_year, :car_model_id => car_model)
              CustomerNumRelation.create(:car_num_id => car_num_record.id, :customer_id => new_customer.id)
            end
          end
        end
        flash[:notice] = "客户信息创建成功。"
      end
    end
    redirect_to "/stores/#{params[:store_id]}/customers"
  end

  def update
    if params[:new_name] and params[:mobilephone]
      customer = Customer.find(params[:id].to_i)
      mobile_c = Customer.where(:status=>Customer::STATUS[:NOMAL],:mobilephone=>params[:mobilephone].strip,
        :store_id=>params[:store_id].to_i).first
      hang_orders = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
        :orders=>{:store_id=>params[:store_id],:customer_id=>customer.id}).count
      if mobile_c and mobile_c.id != customer.id
        flash[:notice] = "手机号码#{params[:mobilephone].strip}在系统中已经存在。"
      else
        if hang_orders > 1 and customer.allowed_debts == Customer::ALLOWED_DEBTS[:YES] and params[:edit_allowed_debts].to_i==Customer::ALLOWED_DEBTS[:NO]
          flash[:notice] = "该客户有挂账未结清，更新失败。"
        else
          customer.update_attributes(:name => params[:new_name].strip, :mobilephone => params[:mobilephone].strip,
            :other_way => params[:other_way].strip, :sex => params[:sex], :birthday => params[:birthday],
            :address => params[:address], :property => params[:edit_property].to_i,
            :group_name => params[:edit_property].to_i==Customer::PROPERTY[:PERSONAL] ? nil : params[:edit_group_name].strip,
            :allowed_debts => params[:edit_allowed_debts].to_i,:is_vip => params[:is_vip],
            :debts_money => params[:edit_allowed_debts].to_i==Customer::ALLOWED_DEBTS[:NO] ? nil : params[:edit_debts_money].to_f,
            :check_type => params[:edit_check_type].nil? ? nil : params[:edit_check_type].to_i,:show_vip=>params[:show_vip],
            :check_time => params[:edit_check_time_month].nil? ? (params[:edit_check_time_week].nil? ? nil : params[:edit_check_time_week].to_i) :  params[:edit_check_time_month].to_i)
          flash[:notice] = "客户信息更新成功。"
        end
      end
    end
    redirect_to request.referer
  end

  def customer_mark
    customer = Customer.find(params[:c_customer_id].to_i)
    customer.update_attributes(:mark => params[:mark].strip) if params[:mark]
    flash[:notice] = "备注成功。"
    redirect_to request.referer
  end

  def single_send_message
    unless params[:content].strip.empty? or params[:m_customer_id].nil?
      MessageRecord.transaction do
        begin
          customer = Customer.find(params[:m_customer_id].to_i)
          content = params[:content].strip.gsub("%name%", customer.name).gsub(" ", "")
          flash[:notice] = message_data(params[:store_id],content,customer,nil,MessageRecord::M_TYPES[:SINGLE_MSG])
        rescue
          flash[:notice] = "短信通道忙碌，请稍后重试。"
        end
      end
    end
    redirect_to request.referer
  end

  def show
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @car_nums = CarNum.find_by_sql(["select c.id c_id, c.num, c.distance distance, cb.name b_name, cm.name m_name, cb.id b_id, cr.customer_id,
        cm.id m_id, c.buy_year,cb.capital_id,c.distance from car_nums c left join car_models cm on cm.id = c.car_model_id
        left join car_brands cb on cb.id = cm.car_brand_id inner join customer_num_relations cr on cr.car_num_id = c.id
        where cr.customer_id = ?", @customer.id])
    order_page = params[:rev_page] ? params[:rev_page] : 1
     @total_orders = Order.one_customer_orders(Order::PRINT_CASH.join(','), params[:store_id].to_i, @customer.id)
    @orders =  @total_orders.paginate(:per_page => 20, :page => order_page)
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, Constant::PER_PAGE, 1)
    comp_page = params[:comp_page] ? params[:comp_page] : 1
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, Constant::PER_PAGE, comp_page)
    @tech_orders = {}
    TechOrder.joins(:staff).where(:order_id=>@complaints.map(&:o_id)).select("staffs.name s_name,order_id").
      group_by{|i|i.order_id}.each{|k,v| @tech_orders[k] = v.map(&:s_name).join("、");}
    svc_card_records_method(@customer.id)  #储值卡记录
    p_card = @customer.pcard_records(params[:store_id])
    @c_pcard_relations = p_card[1].paginate(:page => params[:page] || 1, :per_page => Constant::PER_PAGE) if p_card[1] #套餐卡记录
    @already_used_count = p_card[0]
    @c_svc = CSvcRelation.joins(:sv_card).where(:customer_id=>@customer.id,:status=>CSvcRelation::STATUS[:valid],:sv_cards=>{:types=>SvCard::FAVOR[:DISCOUNT]})
  end
  
  def order_prods
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    if params[:car_num_id]
      @total_orders = Order.find_by_sql(["select * from orders where status in (#{Order::PRINT_CASH.join(',')}) and store_id = ? and customer_id = ?
        and car_num_id= ? order by created_at desc",  @store.id, @customer.id,params[:car_num_id].to_i])
      @orders =  @total_orders.paginate(:per_page => 20, :page => params[:page])
    else
      @total_orders = Order.one_customer_orders(Order::PRINT_CASH.join(','), params[:store_id].to_i, @customer.id)
      @orders =  @total_orders.paginate(:per_page => 20,  :page => params[:page])
    end
   
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    respond_to do |format|
      format.js
    end
  end

  def sav_card_records
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    svc_card_records_method(@customer.id)
  end

  def pc_card_records
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @c_pcard_relations = @customer.pc_card_records_method(params[:store_id])[1].paginate(:page => params[:page] || 1, :per_page => Constant::PER_PAGE) if @customer.pc_card_records_method(params[:store_id])[1]  #套餐卡记录
    @already_used_count = @customer.pc_card_records_method(params[:store_id])[0]
  end

  def revisits
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @revisits = Revisit.one_customer_revists(params[:store_id].to_i, @customer.id, 10, params[:page])
    respond_to do |format|
      format.js
    end
  end

  def complaints
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:id].to_i)
    @complaints = Complaint.one_customer_complaint(params[:store_id].to_i, @customer.id, 10, params[:page])
    @tech_orders = {}
    TechOrder.joins(:staff).where(:order_id=>@complaints.map(&:o_id)).select("staffs.name s_name,order_id").
      group_by{|i|i.order_id}.each{|k,v| @tech_orders[k] = v.map(&:s_name).join("、");}
    respond_to do |format|
      format.js
    end
  end

  def edit_car_num
    car_num_id = params[:id].split("_")[1].to_i
    customer_id = params[:id].split("_")[0]
    current_car_num = CarNum.find_by_id(car_num_id)
    distance = params["car_distance_#{car_num_id}"].to_i
    car_num = CarNum.find_by_num(params["car_num_#{car_num_id}"].strip)
    if car_num.nil? or car_num.id == current_car_num.id
      current_car_num.update_attributes(:num => params["car_num_#{car_num_id}"].strip,:distance => distance,
        :buy_year => params["buy_year_#{car_num_id}"].to_i, :car_model_id => params["car_models_#{car_num_id}"].to_i)
    else
      CustomerNumRelation.create(:car_num_id => car_num.id, :customer_id => customer_id.to_i)
    end
    flash[:notice] = "车牌号码信息修改成功。"
    redirect_to "/stores/#{params["store_id_#{car_num_id}"]}/customers/#{customer_id}"
  end

  def get_car_brands
    respond_to do |format|
      format.json {
        render :json => CarBrand.get_brand_by_capital(params[:capital_id].to_i)
      }
    end
  end

  def get_car_models
    respond_to do |format|
      format.json {
        render :json => CarModel.get_model_by_brand(params[:brand_id].to_i)
      }
    end
  end

  def check_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    respond_to do |format|
      format.json {
        render :json => {:is_has => car_num.nil?}
      }
    end
  end

  def check_e_car_num
    car_num = CarNum.find_by_num(params[:car_num].strip)
    is_has = (car_num.nil? or (!car_num.nil? and (car_num.id == params[:car_num_id].to_i))) ? true : false
    respond_to do |format|
      format.json {
        render :json => {:is_has => is_has}
      }
    end
  end

  def delete_car_num
    ids = params[:id].split("_")
    customer_num_relation = CustomerNumRelation.find_by_car_num_id_and_customer_id(ids[0], ids[1])
    customer_num_relation.destroy
    flash[:notice] = "删除成功。"
    redirect_to request.referer
  end

  def show_revisit_detail    #显示回访详情
    @revisit = Revisit.find_by_id(params[:r_id].to_i)
    respond_to do |format|
      format.js
    end
  end

  def print_orders
    @orders = Order.find(params[:ids].split(","))
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
  end

  def return_order
    @order = Order.joins(:customer).joins("left join work_orders w on w.order_id=orders.id left join stations s on s.id=w.station_id
    left join car_nums c on c.id=orders.car_num_id").select("orders.*,s.name s_name,c.num c_num,customers.name c_name,
    customers.mobilephone phone,customers.group_name").where(:orders=>{:id=>params[:o_id]}).first
    @pay_types = OrderPayType.search_pay_types(params[:o_id])
    @order_prods = OrderProdRelation.order_products(params[:o_id])
    @tech_orders = TechOrder.where(:order_id=>params[:o_id]).group_by{|i|i.order_id}
    staff_ids = ([@order.front_staff_id]|@tech_orders.values.flatten.map(&:staff_id)).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @tech_orders.each{|order_id,tech_orders| @tech_orders[order_id] = tech_orders.map{|tech|@staffs[tech.staff_id]}.join("、")}
  end

  def operate_order
    order = Order.find(params[:order_id])
    msg = "#{order.code}退单成功"
    over = true
    begin
      Order.transaction do
        customer = Customer.find order.customer_id
        order_parm = {:return_reason=>params[:reason],:return_staff_id =>cookies[:user_id]}
        return_parm = {:order_id=>order.id,:order_code=>order.code,:abled_price=>params[:return_fee],
          :pro_types=>params[:item_types],:store_id=>order.store_id}
        if params[:item_types].to_i == 0
          order_parm.merge!(:return_direct => params[:direct])
          return_parm.merge!(:pro_num=>params[:return_num],:return_direct => params[:direct])
        end
        return_types = Order::IS_RETURN[:YES]
        if (params[:item_types].to_i == 0 or params[:item_types].to_i == 1) and  params[:max_num].to_i != params[:return_num].to_i
          return_types = Order::IS_RETURN[:PART]
        end
        order_parm.merge!(:return_types=>return_types)
        if  params[:fact_type]
          store = Store.find order.store_id
          message = "#{customer.name},您好，您在#{store.name}办理的退单，"
          if params[:fact_type].to_i == 1
            reutrn_fee = 0
            if params[:sv_fee] #0 是储值卡  所写金额要退回到客户卡中，不过是匹配到的第一张卡
              reutrn_fee += params[:sv_fee].to_i
              sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:"sv_cards.types"=>SvCard::FAVOR[:SAVE],
                :customer_id=>order.customer_id,:"c_svc_relations.status"=>CSvcRelation::STATUS[:valid]).
                select("c_svc_relations.*,svcard_prod_relations.category_id c_id")
              category_id = Product.find(order.order_prod_relations[0].product_id).category_id
              c_svc_relation_id = nil
              sv_cards.each do |sv_card|
                if sv_card.c_id && sv_card.c_id.split(",").include?("#{category_id}")
                  c_svc_relation_id = sv_card.id
                  break
                end
              end  unless sv_cards.blank?
              if c_svc_relation_id.nil?   #如果查询不到合适的购买记录从而提示信息
                msg = "未查询到可退储值卡"
                over = false
              else
                customer_savecard = CSvcRelation.find(c_svc_relation_id)
                sv_card = SvCard.find customer_savecard.sv_card_id
                SvcardUseRecord.create(:c_svc_relation_id =>c_svc_relation_id, :types => SvcardUseRecord::TYPES[:IN],
                  :use_price => params[:sv_fee], :left_price => customer_savecard.left_price + params[:sv_fee].to_i,:content => "退单退费")
                customer_savecard.update_attribute("left_price", customer_savecard.left_price + params[:sv_fee].to_i)
                message += "已退#{params[:sv_fee].to_i}元到储值卡#{sv_card.name}中，当前余额为#{customer_savecard.left_price}元。"
                message_data(order.store_id,message,customer,nil,MessageRecord::M_TYPES[:BACK_SV])
                ReturnOrder.create(return_parm.merge(:return_type=>0,:return_price=>params[:sv_fee]))
              end
            end
            if params[:cash_fee] #1 是现金
              ReturnOrder.create(return_parm.merge(:return_type=>1,:return_price=>params[:cash_fee]))
              reutrn_fee += params[:cash_fee].to_i
            end
            order_parm.merge!(:return_fee =>reutrn_fee)
          end
          if params[:fact_type].to_i == 0  #退回套餐卡次数
            ReturnOrder.create(return_parm.merge(:return_type=>2)) #2 套餐卡
            oprs = OPcardRelation.find_all_by_order_id(order.id)
            oprs.each do |opr|
              cpr = CPcardRelation.find_by_id(opr.c_pcard_relation_id)
              package_card = PackageCard.find(cpr.package_card_id)
              product = Product.find(opr.product_id)
              if cpr
                pns = cpr.content.split(",").map{|pn| pn.split("-")}
                pns.each do |pn|
                  pn[2] = pn[2].to_i + params[:return_num].to_i if pn[0].to_i == opr.product_id
                end
                cpr.update_attributes({:content=>pns.map{|pn| pn.join("-")}.join(","),:status=>CPcardRelation::STATUS[:NORMAL]})
                message += "已退产品/服务#{product.name}到套餐卡#{package_card.name}中,数量为#{params[:return_num]}。卡内剩余次数为："
                message += pns.map{|pn| "#{pn[1]}#{pn[2]}次"}.join(",")+"。"
                message_data(order.store_id,message,customer,nil,MessageRecord::M_TYPES[:BACK_PCARD])
              end
            end unless oprs.blank?
          end

          if params[:fact_type].to_i == 2
            if params[:item_types].to_i == 2  #套餐卡
              order.c_pcard_relations.update_all(:status=>CPcardRelation::STATUS[:INVALID])
              package_cards = PackageCard.find(order.c_pcard_relations.map(&:package_card_id))
              message += "套餐卡#{package_cards.map(&:name).join(',')}已办理退卡，欢迎选购其他卡类。"
              message_data(order.store_id,message,customer,nil,MessageRecord::M_TYPES[:RETURN_PCARD])
            end
            if params[:item_types].to_i == 3 or  params[:item_types].to_i == 4 #打折卡和储值卡
              order.c_svc_relations.update_all(:status=>CSvcRelation::STATUS[:invalid])
              if params[:item_types].to_i == 4
                c_svc_relations = SvCard.find(order.c_svc_relations.map(&:sv_card_id))
                message += "储值卡#{c_svc_relations.map(&:name).join(',')}已办理退卡，欢迎选购其他卡类。"
                message_data(order.store_id,message,customer,nil,MessageRecord::M_TYPES[:RETURN_SV])
              end
            end
            order_parm.merge!(:return_fee =>params[:cash_fee])
            ReturnOrder.create(return_parm.merge(:return_type=>1,:return_price=>params[:cash_fee])) #1 现金
          end
        end
        if over
          order.update_attributes(order_parm)
          work_order = order.work_orders[0]
          if work_order && WorkOrder::NO_END.include?(work_order.status)
            work_order.update_attributes(:status=>WorkOrder::STAT[:CANCELED])
          end
          if params[:item_types].to_i == 0
            if params[:direct].to_i == Order::O_RETURN[:REUSE]  #增加物料
              order_products = order.order_prod_relations.group_by { |opr| opr.product_id }
              unless order_products.empty?  #如果是产品,则减掉要加回来
                Material.find_by_sql(["select m.id, pmr.product_id from materials m inner join prod_mat_relations pmr
                on pmr.material_id = m.id inner join products p on p.id = pmr.product_id
                where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and pmr.product_id in (?)", order_products.keys]).each do |m|
                   Material.update_storage(m.id,m.storage + params[:return_num].to_i,cookies[:user_id],"退单回库物料",nil,order)
                end
              end
            else
              material_id = ProdMatRelation.where(:product_id=>params[:product_id]).first.material_id
              MaterialLoss.create(:loss_num =>params[:return_num],:staff_id => cookies[:user_id],
                :store_id=>order.store_id,:material_id => material_id,:remark=>"退单报损")
            end
          end
        end
      end
    rescue
      msg = "#{order.code}退单失败"
    end
    render :json =>{:msg=>msg}
  end

  def add_car_get_datas #添加车辆 查找
    @type = params[:type].to_i
    id = params[:id].to_i
    if @type==0
      @brands = CarBrand.where(["capital_id = ?", id])
    elsif @type==1
      @models = CarModel.where(["car_brand_id= ?", id])
    end
  end

  def add_car #添加车牌
    cid = params[:add_car_cus_id].to_i
    buy_year = params[:add_car_buy_year].to_i
    car_num = params[:add_car_num].strip
    car_model = params[:add_car_models].to_i
    distance = params[:add_car_distance].to_i
    car_num_record = CarNum.find_by_num(car_num)
    if car_num_record
      cnr = CustomerNumRelation.find_by_car_num_id(car_num_record.id)
      if cnr and cnr.customer_id != cid
        cnr.update_attribute("customer_id", cid)
        car_num_record.update_attributes(:car_model_id => car_model, :buy_year => buy_year, :distance => distance)
        flash[:notice] = "车牌号码为"+car_num+"的车辆已关联到当前客户名下!"
      elsif cnr and cnr.customer_id == cid
        flash[:notice] = "添加失败,该客户已关联该车辆!"
      else
        car_num_record.update_attributes(:car_model_id => car_model, :buy_year => buy_year, :distance => distance)
        CustomerNumRelation.create(:customer_id => cid, :car_num_id => car_num_record.id)
        flash[:notice] = "添加成功!"
      end
    else
      new_num_record = CarNum.create(:num => car_num, :car_model_id => car_model, :buy_year => buy_year, :distance => distance)
      CustomerNumRelation.create(:customer_id => cid, :car_num_id => new_num_record.id)
      flash[:notice] = "添加成功!"
    end
    redirect_to "/stores/#{params[:store_id]}/customers/#{cid}"
  end


  def select_order
    @store = Store.find(params[:store_id].to_i)
    @customer = Customer.find(params[:customer_id].to_i)
    order_page = params[:rev_page] ? params[:rev_page] : 1
    @total_orders = Order.find_by_sql(["select * from orders where status in (#{Order::PRINT_CASH.join(',')}) and store_id = ? and customer_id = ?
        and car_num_id= ? order by created_at desc",  @store.id, @customer.id,params[:car_num_id]])
    @orders =  @total_orders.paginate(:per_page => 20, :page => order_page)
    @product_hash = OrderProdRelation.order_products(@orders)
    @order_pay_type = OrderPayType.order_pay_types(@orders)
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
  end
  private
  
  def svc_card_records_method(customer_id)
    #储值卡记录
    @svcard_records = SvcardUseRecord.paginate_by_sql(["select sur.*,sc.name sc_name,csr.order_id  from svcard_use_records sur
      inner join c_svc_relations csr on csr.id = sur.c_svc_relation_id inner join sv_cards sc on csr.sv_card_id = sc.id
    where csr.customer_id = ? and csr.status = 1 order by sur.c_svc_relation_id,sur.created_at asc", customer_id], :page => params[:page],
      :per_page => Constant::PER_PAGE)
    @srs = @svcard_records.group_by{|sr|sr.c_svc_relation_id} if @svcard_records
  end

  
end
