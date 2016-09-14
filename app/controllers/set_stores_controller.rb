#encoding: utf-8
class SetStoresController < ApplicationController
  layout "role" ,:except =>["single_print","three_line_print"]
  before_filter :sign?, :except => [:update]
  require 'will_paginate/array'
  
  def index
    @store = Store.find_by_id(params[:store_id].to_i)
    @store_city = City.find_by_id(@store.city_id) if @store.city_id
    @cities = City.where(["parent_id = ?", @store_city.parent_id]) if @store_city
    @province = City.where(["parent_id = ?", City::IS_PROVINCE])
  end

  def update
    store = Store.find_by_id(params[:id].to_i)
    update_sql = {:name => params[:store_name].strip, :address => params[:store_address].strip, :phone => params[:store_phone].strip,
      :contact => params[:store_contact].strip, :position => params[:store_position_x]+","+params[:store_position_y],
      :opened_at => params[:store_opened_at], :status => params[:store_status].to_i, :city_id => params[:store_city].to_i,
      :cash_auth => params[:store_cash_auth].to_i,:auto_send=>params[:auto_send],:store_intro => params[:store_intro]}
    update_sql.merge!(:limited_password=>Digest::MD5.hexdigest(params[:limited_password])) if permission?(:base_datas, :edit_limited_pwd) && params[:limited_password]!=""
    if store.update_attributes(update_sql)
      if params[:store_img]
        begin
          store.update_attribute("img_url", Sale.upload_img(params[:store_img],store,Constant::STORE_PICSIZE << Constant::STORE_PICS))
       rescue
          flash[:notice] = "图片上传失败!"
       end
      end
      cookies.delete(:store_name) if cookies[:store_name]
      cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
      flash[:notice] = "设置成功!"
    else
      flash[:notice] = "更新失败!"
    end
    redirect_to store_set_stores_path
  end

  def select_cities   #选择省份时加载下面的所有城市
    p_id = params[:p_id]
    @cities = City.where(["parent_id = ?", p_id])
  end


  def cash_register
    @title = "收银"
    about_cash(params[:store_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def complete_pay
    @title = "收银"
    start_time = params[:first].nil? || params[:first] == "" ? Time.now.at_beginning_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:first]}"
    end_time = params[:last].nil? || params[:last] == "" ? Time.now.end_of_day.strftime("%Y-%m-%d %H:%M") : Time.now.strftime("%Y-%m-%d")+" #{params[:last]}"
    sql = "date_format(orders.updated_at,'%Y-%m-%d %H:%i')>='#{start_time}' and date_format(orders.updated_at,'%Y-%m-%d %H:%i')<='#{end_time}'"
    unless params[:c_num].nil? || params[:c_num] == ""
      sql += " and car_nums.num like '%#{params[:c_num]}%'"
    end
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,
      customers.mobilephone phone,customers.name c_name,customers.group_name,car_nums.num c_num,w.station_id s_id,customers.id c_id").
      where(:status=>Order::OVER_CASH,:store_id=>params[:store_id]).where(sql).order("orders.updated_at desc")
    @pays = OrderPayType.where(:order_id=>orders.map(&:id)).select("sum(price) total_price,pay_type").group("pay_type").inject(Hash.new){
      |hash,pay|hash[pay.pay_type] = pay.total_price;hash}
    @orders = orders.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @pay_types = OrderPayType.pay_order_types(@orders.map(&:id))
    @tech_orders = TechOrder.where(:order_id=>@orders.map(&:id)).group_by{|i|i.order_id}
    staff_ids = (@orders.map(&:front_staff_id)|@tech_orders.values.flatten.map(&:staff_id)).compact.uniq
    @staffs = Staff.where(:id =>staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @tech_orders.each{|order_id,tech_orders| @tech_orders[order_id] = tech_orders.map{|tech|@staffs[tech.staff_id]}.join("、")}
    @stations = Station.find(@orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def about_cash(store_id)
    orders = Order.joins([:car_num,:customer]).joins("left join work_orders w on w.order_id=orders.id").select("orders.*,customers.mobilephone,
   customers.name c_name,customers.group_name,car_nums.num c_num,car_nums.id n_id,w.station_id s_id,customers.id c_id").where(:status=>Order::CASH,
      :store_id=>store_id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(orders.map(&:id))
    @orders = orders.group_by{|i|{:c_name=>i.c_name,:c_num=>i.c_num,:tel=>i.mobilephone,:g_name=>i.group_name,:c_id=>i.c_id,:n_id=>i.n_id} }
    @order_pays = OrderPayType.search_pay_order(orders.map(&:id))
    @techs = TechOrder.where(:order_id=>orders.map(&:id)).group_by{|i|i.order_id}
    staff_ids = (@techs.values.flatten.map(&:staff_id)|orders.map(&:front_staff_id)).compact.uniq
    @staffs = Staff.where(:id =>staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @techs.each{|order_id,tech_orders| @techs[order_id] = tech_orders.map{|tech|@staffs[tech.staff_id]}.join("、")}
    @stations = Station.find(orders.map(&:station_id).compact.uniq).inject(Hash.new){|hash,s|hash[s.id]=s.name;hash}
  end

  def load_order
    @customer = Customer.find params[:customer_id]
    @car_num = CarNum.find params[:car_num_id]
    @orders = Order.select("orders.*").where(:status=>Order::CASH,:store_id=>params[:store_id],:customer_id=>params[:customer_id],
      :car_num_id=>@car_num.id).order("orders.created_at desc")
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    prod_ids = OrderProdRelation.joins(:product).where(:order_id=>@orders.map(&:id)).select("products.category_id").map(&:category_id)
    @cates = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good], Category::TYPES[:service]]).inject(Hash.new){|hash,c|
      hash[c.id]=c.name;hash}
    sv_pcard = CPcardRelation.joins(:package_card).select("package_card_id p_id").where(:customer_id=>params[:customer_id],:order_id=>@orders.map(&:id),
      :status=>CPcardRelation::STATUS[:INVALID]).map(&:p_id)
    @sv_card = []
    unless prod_ids.blank? && sv_pcard.blank?
      sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:customer_id=>@customer.id,:"sv_cards.types" => SvCard::FAVOR[:SAVE]).where("
      c_svc_relations.status=#{CSvcRelation::STATUS[:valid]} or order_id in (#{@orders.map(&:id).join(',')})").select("c_svc_relations.*,sv_cards.name,
      sv_cards.store_id,svcard_prod_relations.category_id ci,svcard_prod_relations.pcard_ids pid,c_svc_relations.status sa,order_id o_id").where("sv_cards.store_id=#{params[:store_id]}")
      sv_cards.each do |sv|
        prod_ids.each do |ca|
          if sv.ci  and sv.ci.split(",").include? "#{ca}"
            @sv_card  << sv
            break
          end
        end
        sv_pcard.each do |p_id|
          if sv.pid  and sv.pid.split(",").include? "#{p_id}"
            @sv_card  << sv
            break
          end
        end
      end
    end
    @order_pays = OrderPayType.search_pay_order(@orders.map(&:id))
  end

  def pay_order
    @may_pay = deal_order(request.parameters)
    about_cash(params[:store_id])  if @may_pay[0]
  end

  def single_print
    @store = Store.find params[:store_id]
    order_ids = params[:order_id].split(",")
    @orders = Order.where(:store_id=>params[:store_id],:id=>order_ids)
    @tech_orders = TechOrder.joins(:staff).where(:order_id=>order_ids).select("staffs.name,order_id").group_by{|i|i.order_id}
    @customer = Customer.where(:id=>@orders.map(&:customer_id).compact.uniq).first
    @car_nums = CarNum.joins(:orders).where(:id=>@orders.map(&:car_num_id)).select("num")
    @staffs = Staff.where(:id=>@orders.map(&:front_staff_id)).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(order_ids).values.flatten.group_by{|i|i.item_types}
    @order_pays = OrderPayType.search_pay_types(order_ids)
    order_pids = @orders.map(&:c_pcard_relation_id).compact.uniq
    sql = " 1=1"
    unless order_pids.blank?
      sql += " or package_cards.id in (#{@orders.map(&:c_pcard_relation_id).join(',')})"
    end
    @pcards = CPcardRelation.joins(:package_card).where(:customer_id=>@customer.id,:status=>CPcardRelation::STATUS[:NORMAL]).where(sql).
      select("package_cards.name,content")
    @cash_pay = OrderPayType.joins(:order).where(:order_id=>order_ids,:pay_type=>OrderPayType::PAY_TYPES[:CASH]).
      select("ifnull(sum(pay_cash),0) pay_cash,ifnull(sum(second_parm),0) second_parm").first
    @favour_notices = OrderPayType.joins(:order).where(:order_id=>order_ids,:pay_type=>OrderPayType::PAY_TYPES[:FAVOUR]).
      select("second_parm,customer_id c_id")
    p @sv_cards = SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("sv_cards.name,min(svcard_use_records.left_price) left_price").where("customer_id=#{@customer.id}").group("c_svc_relation_id")
  end

  def three_line_print
    @store = Store.find params[:store_id]
    @orders = Order.where(:id=>params[:o_id].split(',').compact.uniq)
    @customer = Customer.where(:id=>@orders.map(&:customer_id).compact.uniq).first
    @car_num = CarNum.where(:id=>@orders.map(&:car_num_id).compact.uniq)
    staff_ids = @orders.map(&:cons_staff_id_1).compact.uniq
    staff_ids.delete 0
    @staffs = Staff.find(staff_ids).inject(Hash.new){|hash,staff|hash[staff.id]=staff.name;hash}
    @order_prods = OrderProdRelation.order_products(@orders.map(&:id))
    @order_pays = OrderPayType.pay_order_types(@orders.map(&:id))
  end


  def edit_svcard
    CSvcRelation.find(params[:card_id]).update_attributes(:id_card=>params[:number])
    render :json=>{:card_id=>params[:card_id],:number=>params[:number]}
  end

  def plus_items
    @title = "业务开单"
    @suit_cards,@pcard = [],[]
    if params[:num] && params[:num].length
      store_id = chain_store(params[:store_id])
      @num = params[:num]
      @customer = CarNum.search_customer(@num,store_id)
      if @customer
        pp = CSvcRelation.search_card(@customer.id,params[:store_id])
        @pcard =  pp[2]
        @suit_cards = pp[0]
        @prod = pp[1]
      end
    end
  end


  def search_item
    type,content,store_id = params[:item_id].to_i,params[:item_name],params[:store_id].to_i
    sql,@suitable = [""],{}
    if type == Category::ITEM_NAMES[:CARD] #如果是卡类
      @cates = SvCard::S_FAVOR.merge(2=>"套餐卡")
      stores_id = chain_store(params[:store_id])  #获取该门店所有的连锁店
      sv_sql = "select * from sv_cards where  status=#{SvCard::STATUS[:NORMAL]}"
      if stores_id.blank?   #若该门店无其他连锁店
        sv_sql += " and store_id=#{store_id}"
      else    #若该门店有其他连锁店
        sv_sql += " and ((store_id=#{store_id} and use_range=#{SvCard::USE_RANGE[:LOCAL]}) or (store_id in (#{stores_id.join(',')}) and use_range =#{SvCard::USE_RANGE[:CHAINS]}))"
      end
      sv_sql += " and name like '%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%'" unless content.nil? || content.empty? || content == ""
      sv_cards = SvCard.find_by_sql(sv_sql).group_by{|i|i.types}   #获取该门店的优惠卡及其同连锁店下面的门店的使用范围为连锁店的优惠卡
      sv_cards.each do |k,cards|
        suit_cards = []
        if k == SvCard::FAVOR[:SAVE]
          cates = Category.where(:types=>Category::DATA_TYPES,:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}.merge!(Product::PACK_SERVIE)
          pcards = PackageCard.where(:status=>PackageCard::STAT[:NORMAL],:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}
          svp = SvcardProdRelation.where(:sv_card_id=>cards.map(&:id)).inject({}){|h,c|
            h[c.sv_card_id]=[c.category_id.nil? ? nil : c.category_id.split(','),c.pcard_ids.nil? ? nil : c.pcard_ids.split(',')]}
          cards.each do |card|
            field = svp[card.id] && svp[card.id][0] ? svp[card.id][0].map { |i| cates[i.to_i]}.uniq.compact.join(",") : ""
            field += svp[card.id] && svp[card.id][1] ? svp[card.id][1].map { |i| pcards[i.to_i]}.uniq.compact.join(",") : ""
            suit_cards << {:name=>card.name,:price=>card.price,:id=>card.id,:suit_field =>field,:type=>k,:status=>params[:checked_item].include?("#{type}_#{k}_#{card.id}")}
          end
        elsif k == SvCard::FAVOR[:DISCOUNT]
          p_fields = Product.find_by_sql("select group_concat(name,'-',round(sp.product_discount/10,1),'折')  name,sp.sv_card_id s_id from
         products p inner join svcard_prod_relations sp on sp.product_id=p.id where p.status=#{Product::IS_VALIDATE[:YES]} and
         sp.sv_card_id in (#{cards.map(&:id).join(',')}) group by sp.sv_card_id").inject({}){|h,s|h[s.s_id]=s.name.force_encoding('utf-8');h}
          cards.each do |card|
            suit_cards << {:name=>card.name,:price=>card.price,:id=>card.id,:suit_field =>p_fields[card.id],:type=>k,:status=>params[:checked_item].include?("#{type}_#{k}_#{card.id}")}
          end
        end
        @suitable[k] = suit_cards unless suit_cards.blank?
      end unless sv_cards == {}
     
      #获取该门店所有的套餐卡及其所关联的物料
      suit_pcard = []
      sql2 = ["select p.* from package_cards p where p.store_id=? and ((p.date_types=?) or (p.date_types=? and NOW()<=p.ended_at))
     and p.status=?",store_id, PackageCard::TIME_SELCTED[:END_TIME],PackageCard::TIME_SELCTED[:PERIOD], PackageCard::STAT[:NORMAL]]
      unless content.nil? || content.empty? || content == ""
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      p_cards = PackageCard.find_by_sql(sql2)
      pmrs = PcardMaterialRelation.joins(:material).select("package_card_id p_id,material_id m_id,storage-material_num result").
        where(:package_card_id =>p_cards.map(&:id)).group("package_card_id").inject({}){|h,p|h[p.p_id]=p.result;h}
      unless p_cards.blank?
        card_fields = Product.find_by_sql("select group_concat(name,':',pr.product_num,'次')  name,pr.package_card_id s_id from
         products p inner join pcard_prod_relations pr on pr.product_id=p.id where p.status=#{Product::IS_VALIDATE[:YES]} and
         pr.package_card_id in (#{p_cards.map(&:id).join(',')}) group by pr.package_card_id").inject({}){|h,s|h[s.s_id]=s.name.force_encoding('utf-8');h}
        p_cards.each do |p_card|
          if pmrs[p_card.id].nil?
            suit_pcard << {:name=>p_card.name,:price=>p_card.price,:id=>p_card.id,:suit_field =>card_fields[p_card.id],:type=>2,:status=>params[:checked_item].include?("#{type}_#{2}_#{p_card.id}")}
          else
            if pmrs[p_card.id] >= 0
              suit_pcard << {:name=>p_card.name,:price=>p_card.price,:id=>p_card.id,:suit_field =>card_fields[p_card.id],:type=>2,:status=>params[:checked_item].include?("#{type}_#{2}_#{p_card.id}")}
            end
          end
        end
      end
      @suitable[2] = suit_pcard unless suit_pcard.blank?
    else   #如果是产品或者服务
      buy_type =  5
      @cates = Category.where(:types=>type,:store_id=>store_id).inject({}){|h,c|h[c.id]=c.name;h}.merge!(Product::PACK_SERVIE)
      sql = "select p.* from  products p inner join  categories c on c.id=p.category_id where p.store_id=#{store_id} and p.status=#{Product::IS_VALIDATE[:YES]} "
      unless content.nil? || content.empty? || content == ""
        sql += " and p.name like '%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%'"
      end
      if type == Category::ITEM_NAMES[:PROD] #如果是产品
        buy_type =  6
        sql += " and c.types=#{Category::TYPES[:good]}"
        result = Product.find_by_sql(sql).group_by{|i|i.category_id}
        total_prms = ProdMatRelation.joins(:material).where(:product_id=>result.values.flatten.map(&:id)).select(
          "ifnull(FLOOR(materials.storage/material_num),0) num,product_id,material_id").group_by{|i|i.product_id}
        result.each do |k,prod_servs|
          suit_storage = []
          prod_servs.each do |r|
            if total_prms[r.id]
              available = true
              available_num = []
              total_prms[r.id].each do |prm|
                if prm.num <= 0
                  available = false
                  break
                end
                available_num << prm.num
              end
              if available
                suit_storage << {:storage=>available_num.min,:name=>r.name,:price=>r.sale_price,:id=>r.id,:type=>buy_type,:status=>params[:checked_item].include?("#{k}_#{type}_#{r.id}")}
              end
            end
          end
          @suitable[k] = suit_storage unless suit_storage.blank?
        end
      elsif type == Category::ITEM_NAMES[:SERVICE]
        sql += " and c.types=#{Category::TYPES[:service]} and  single_types=#{Product::SINGLE_TYPE[:SIN]}"
        result = Product.find_by_sql(sql).group_by{|i|i.category_id}
        result.each do |k,prod_servs|
          suit_storage = []
          prod_servs.each do |r|
            suit_storage << {:storage=>999,:name=>r.name,:price=>r.sale_price,:id=>r.id,:type=>buy_type,
              :status=>params[:checked_item].include?("#{k}_#{type}_#{r.id}")}
          end
          @suitable[k] = suit_storage unless suit_storage.blank?
        end
      end
    end
  end

  def search_info
    store_id = chain_store(params[:store_id])
    @num = params[:car_num]
    @customer = CarNum.search_customer(@num,store_id)
    @suit_cards = []
    if @customer
      pp = CSvcRelation.search_card(@customer.id,params[:store_id])
      @pcard =  pp[2]
      @suit_cards = pp[0]
      @prod = pp[1]
    end
  end

  def submit_item
    #    begin
    Order.transaction do
      store_id = chain_store(params[:store_id])
      @num = params[:car_num]
      @customer = CarNum.search_customer(@num,store_id)
      car_num = CarNum.where(:num =>@num).first
      if params[:customer_id] && params[:customer_id].to_i != 0
        car_num = CarNum.create(params[:car_info].merge({:num=>@num}))  if car_num.nil?
        CustomerNumRelation.where(:customer_id=>@customer.id,:car_num_id=>car_num.id).delete_all  unless @customer.nil?
        @customer = Customer.find(params[:customer_id])  #为后续使用
        @customer.update_attributes(params[:customer])
        @customer.customer_num_relations.create({:customer_id =>@customer.id, :car_num_id => car_num.id})
      else
        if @customer.nil?
          property = Customer::PROPERTY[params[:customer][:group_name].nil? ? :PERSONAL : :GROUP ]
          @customer = Customer.create(params[:customer].merge({ :property => property,:store_id=>params[:store_id],
                :status => Customer::STATUS[:NOMAL], :allowed_debts => Customer::ALLOWED_DEBTS[:NO]}))
          car_info = params[:car_info].nil? ? {:num=>@num} : params[:car_info].merge({:num=>@num})
          car_num = CarNum.create(car_info)  if car_num.nil?
          @customer.customer_num_relations.create({:customer_id => @customer.id, :car_num_id => car_num.id})
        else
          @customer = Customer.find(@customer.id)  #为后续使用
          @customer.update_attributes(params[:customer])
        end
      end
    
      total_info,total_prod = {},{}
      params[:sub_items].map do |info,num|
        split_info = info.split("_")
        total_info[split_info[1].to_i].nil? ?  total_info[split_info[1].to_i]={info=>num.to_i} : total_info[split_info[1].to_i][info] = num.to_i
        if  CSvcRelation::SEL_PROD.include? split_info[1].to_i  #购买的包含产品的时候
          total_prod[0].nil? ? total_prod[0] = [split_info[2] ] : total_prod[0] << split_info[2]
        elsif CSvcRelation::SEL_SV.include? split_info[1].to_i #购买的包含储值卡 打折卡
          total_prod[1].nil? ? total_prod[1] = [split_info[2] ] : total_prod[1] << split_info[2]
        elsif split_info[1].to_i == CSvcRelation::SEL_METHODS[:PCARD] #购买的包含摊餐卡
          total_prod[2].nil? ? total_prod[2] = [split_info[2] ] : total_prod[2] << split_info[2]
        end
      end
      @msg = create_item(total_info,total_prod,@customer,car_num,cookies[:user_id],params[:store_id].to_i)
    end
    #    rescue
    #      @msg = [["开单失败"],false]
    #    end
  end

  def edit_deduct
    @tech_orders = TechOrder.where(:order_id=>params[:order_id])
    @staffs = Staff.where(:id=>@tech_orders.map(&:staff_id)).inject({}){|h,s|h[s.id]=s.name;h}
    @order = Order.find(params[:order_id])
  end

  def post_deduct
    begin
      status = 0
      total_deduct = params[:ids].values.inject(0){|num,n|num+n.to_i}
      Order.find(params[:order_id]).update_attributes(:technician_deduct=>total_deduct)
      tech_orders = TechOrder.find(params[:ids].keys)
      tech_orders.each do |tech_order|
        deduct = params[:ids]["#{tech_order.id}"]
        tech_order.update_attributes(:own_deduct=>deduct)
      end
    rescue
      status = 1
    end
    render :json=>{:status=>status}
  end


  def search_num
    @customers = Customer.where(:mobilephone=>params[:mobilephone],:store_id=>params[:store_id],:status=>Customer::STATUS[:NOMAL])
  end
end