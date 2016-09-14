#encoding: utf-8
class Api::ChangeController < ApplicationController

  def change_pwd
    sv_card = CSvcRelation.find_by_id(params[:cid].to_i)
    SvCard.transaction do
      status = 0
      msg = ""
      if sv_card && sv_card.status
        if params[:verify_code] == sv_card.verify_code
          n_password = params[:n_password]
          if sv_card.update_attribute(:password, Digest::MD5.hexdigest(n_password))
            status = 0
            msg = "密码修改成功!"
          else
            status = 2
            msg = "修改失败!"
          end
        else
          status = 1
          msg = "验证码不正确!"
        end
      else
        status = 2
        msg = "数据错误!"
      end
      render :json => {:msg_type => status, :msg => msg}
    end
  end

  def send_code
    csvc_relaion = CSvcRelation.find_by_id(params[:cid].to_i)
    c_phone = csvc_relaion.customer
    if csvc_relaion
      begin
        csvc_relaion.update_attribute(:verify_code, proof_code(6).downcase)
        send_message = "#{csvc_relaion.sv_card.name}的余额为#{csvc_relaion.left_price}，本次验证码：#{csvc_relaion.verify_code}。"
        msg = message_data(c_phone.store_id,send_message,c_phone,nil,MessageRecord::M_TYPES[:CHANGE_SV])
        msg_type = 0
      rescue
        msg_type =1
        msg = "发送失败"
      end
    else
      msg_type =1
      msg = "用户或储值卡不存在"
    end
    render :json=>{:msg_type=>msg_type,:msg=>msg}

  end

  def sv_records
    render :json => SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("name,content,use_price,svcard_use_records.left_price,
    date_format(svcard_use_records.created_at,'%Y.%m.%d') created_at").where("sv_cards.store_id=#{params[:store_id]} and
   c_svc_relations.customer_id=#{params[:customer_id]}").where(:types=>SvcardUseRecord::TYPES[:OUT]).group_by{|i|i.name}
    #   sv_cards = SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("sv_cards.name sname,sv_cards.id sid,
    #svcard_use_records.content,svcard_use_records.use_price,svcard_use_records.left_price,date_format(svcard_use_records.created_at,'%Y-%m-%d') created_at#").where("sv_cards.store_id=#{2} and
    #  c_svc_relations.customer_id=#{1}#").where(:types=>SvcardUseRecord::TYPES[:OUT]).group_by{|sc|sc.sid}
    #      svcards_records = []
    #      sv_cards.each do |k, v|
    #        a = {}
    #        b = []
    #        a[:id] = k
    #        a[:name] = v[0].sname
    #        v.each do |obj|
    #          c = {}
    #          c[:content] = obj.content
    #          c[:time] = obj.created_at
    #          c[:u_price] = obj.use_price
    #          c[:l_price] = obj.left_price
    #          b << c
    #        end
    #        a[:records] = b
    #        svcards_records << a
    #      end
    #      render :json => svcards_records
  end

  def use_svcard
    records = CSvcRelation.find_by_sql(["select csr.* from c_svc_relations csr
      left join customers c on c.id = csr.customer_id inner join sv_cards sc on sc.id = csr.sv_card_id
      where sc.types = 1 and csr.password = ? and csr.status = ? and csr.customer_id = ?",
        Digest::MD5.hexdigest(params[:password].strip), CSvcRelation::STATUS[:valid], params[:customer_id].to_i])
    status = 0
    message = ""
    price = params[:price].to_f
    SvcardUseRecord.transaction do
      if !records.blank? 
        status = 0
        message = "余额不足!"
        records.each do |r|
          if r.left_price.to_f >= price
            SvcardUseRecord.create(:c_svc_relation_id => r.id, :types => SvcardUseRecord::TYPES[:OUT],
              :use_price => price, :left_price => r.left_price - price, :content => params[:content].strip)
            r.update_attribute(:left_price, (r.left_price - price))
            status = 1
            message = "支付成功!"
            break
          end
        end
      else
        status = 0
        message = "密码错误!"
      end
      render :json => {:content => message, :status => status}
    end
  end


  #将意向单或者预约单转为工单
  def change_to_order
    #    user_id 下单的技师提成
    reserv = Reservation.where(:store_id=>params[:store_id],:id=>params[:v_id]).first
    msg = "转为正单成功，请查看"
    status = 1
    if reserv.nil?
      status = 0
      msg = "预约单/意向单不存在"
    else
      customer = Customer.find reserv.customer_id
      order_parm = {:car_num_id => reserv.car_num_id,:is_billing => false,:front_staff_id =>params[:user_id],
        :customer_id=>reserv.customer_id,:store_id=>params[:store_id],:is_visited => Order::IS_VISITED[:NO],
        :code => MaterialOrder.material_order_code(params[:store_id]),:status => Order::STATUS[:WAIT_PAYMENT]}
      if reserv.prod_types < 2
        price = reserv.types == Reservation::TYPES[:PURPOSE] ? params[:prod_price] : nil
        result = OrderProdRelation.make_record(reserv.prod_id,params[:prod_num].to_i,params[:user_id],customer.id,reserv.car_num_id,params[:store_id],price)
        order = result[3]
        status = result[0]
        msg =  result[1] if result[0] == 0
      elsif reserv.prod_types == 2
        pcard = PackageCard.find(reserv.prod_id)
        card_content = PcardProdRelation.find_by_sql("select group_concat(p.id,'-',p.name,'-',ppr.product_num) content from
         pcard_prod_relations ppr  inner join products p on ppr.product_id=p.id where ppr.package_card_id= #{reserv.prod_id}").first.content
        pmrs = PcardMaterialRelation.joins(:material).where(:package_card_id=>reserv.prod_id).select("package_card_id p_id,material_id m_id,storage-material_num result").first
        if pmrs.nil? || ((pmrs && pmrs.result >= 0) && card_content) #如果套餐卡未绑定物料 或者 剩余库存大于0 且有内容的才可以购买
          time = pcard.is_auto_revist ? Time.now + pcard.auto_time.to_i.hours : nil
          price = reserv.types == Reservation::TYPES[:PURPOSE] ? reserv.prod_price : pcard.price
          order = Order.create(order_parm.merge({:types => Order::TYPES[:SAVE],:auto_time =>time,
                :warn_time => pcard.auto_warn ? Time.now + pcard.time_warn.to_i.days : nil,:price=>price}))
          ended_at = pcard.date_types == PackageCard::TIME_SELCTED[:PERIOD] ? pcard.ended_at : Time.now + pcard.date_month.to_i.days
          c_pcard = CPcardRelation.create(:customer_id =>reserv.customer_id,:package_card_id => pcard.id, :ended_at => ended_at.strftime("%Y-%m-%d")+" 23:59:59",:price => price,
            :status => CPcardRelation::STATUS[:INVALID], :content => card_content, :order_id => order.id)
          m_types = MessageRecord::M_TYPES[:BUY_PCARD]
          send_message = "#{customer.name}：您好，您购买的套餐卡:#{pcard.name}："
          c_pcard.content.split(",").each do |single_card|
            name = single_card.split('-')[1].force_encoding("ASCII-8BIT").force_encoding("UTF-8")
            send_message += "#{name}#{single_card.split('-')[2]}次，"
          end
          send_message += "有效期截至#{ended_at.strftime("%Y-%m-%d")}。"
          Material.update_storage(pmrs.m_id,pmrs.result,params[:user_id],"pad销售套餐卡扣物料",nil,order) if pmrs #更新库存并生成出库记录
        else
          msg =  "#{pcard.name} 库存不足！"
          status = 0
        end
      elsif reserv.prod_types == 3
        card = SvCard.find reserv.prod_id
        price = reserv.types == Reservation::TYPES[:PURPOSE] ? reserv.prod_price : card.price
        order = Order.create(order_parm.merge({:types => Order::TYPES[:DISCOUNT],:price=>price}))
        CSvcRelation.create(:customer_id=>reserv.customer_id,:sv_card_id =>reserv.prod_id, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
      elsif reserv.prod_types == 4
        m_types = MessageRecord::M_TYPES[:BUY_SV]
        card = SvCard.find reserv.prod_id
        price = reserv.types == Reservation::TYPES[:PURPOSE] ? reserv.prod_price : card.price
        order = Order.create(order_parm.merge({:types => Order::TYPES[:SAVE],:price=>price}))
        sv_prod = SvcardProdRelation.select("ifnull(sum(base_price+more_price),0) price").where(:sv_card_id=>reserv.prod_id).first
        CSvcRelation.create(:customer_id =>reserv.customer_id,:sv_card_id =>reserv.prod_id, :order_id => order.id,
          :status => CSvcRelation::STATUS[:invalid],:total_price =>sv_prod.price,  :left_price =>sv_prod.price,
          :id_card=>add_string(8,CSvcRelation.joins(:customer).where(:"customers.store_id"=>params[:store_id]).count),
          :password=>Digest::MD5.hexdigest("#{customer.mobilephone[-6..-1]}"))
        send_message = "#{customer.name}：您好，您购买的储值卡#{card.name},余额为#{sv_prod.price}元，密码是#{customer.mobilephone[-6..-1]}，请您尽快付款使用。"
      end
      if status == 1
        message_data(params[:store_id],send_message,customer,reserv.car_num_id,m_types)  if m_types
        reserv.update_attributes({:order_id=>order.id,:status=>Reservation::STATUS[:confirmed]})
      end
    end
    render :json=>{:status=>status,:msg=>msg}
  end

  #取消意向单或者预约单
  def cancel_reserv
    begin
      Reservation.where(:store_id=>params[:store_id],:id=>params[:v_id].split(",")).update_all status: Reservation::STATUS[:cancel ]
      status = 1
      msg = "取消成功"
    rescue
      status = 0
      msg = "取消失败"
    end
    render :json=>{:status=>status, :msg=> msg}
  end
  

  def get_quickly_service
    render :json=>{:services =>Product.services(params[:store_id])}  #常用服务
  end

  def load_reserv
    reservs = Reservation.total_reserv(params[:store_id],Reservation::TYPES[:RESER])
    customers = Customer.load_customers(reservs.map(&:customer_id).compact.uniq)
    car_nums = CarNum.load_car_num(reservs.map(&:car_num_id).compact.uniq)
    reserv_prods = {}
    reservs.group_by{|i|i.prod_types}.each {|k,v|
      model = k < 2 ? Product : (k == 2 ? PackageCard : SvCard)
      reserv_prods[k]= model.where(:id=>v.map(&:prod_id).compact.uniq).inject({}){|h,prod|
        h[prod.id]={:name=>prod.name,:price=>prod.attributes["price"]||=prod.attributes["sale_price"],
          :img_url=>prod.img_url.nil? ? "" : prod.img_url.gsub("img#{prod.id}","img#{prod.id}_#{Constant::P_PICSIZE[1]}")};h}
    }
    render :json=>{:reservs =>reservs,:customers=>customers,:car_nums=>car_nums,:reserv_prods=>reserv_prods}  #常用服务
  end
  
  def change_status
    status = 0
    begin
      station = Station.where(:id=>params[:station_id]).first
      station.locked = params[:lock]
      if station.save
        status = 1 
      end
    rescue
    end
    render :json=>{:status=>status}
  end


  #根据实际情况调换工位
  def change_station
    #参数 "(work_order_id)_(station_id),(work_order_id)_(station_id)", store_id
    status = 0
    msg = ""
    if params[:wo_station_ids]
      WorkOrder.transaction do
        wo_station_ids = params[:wo_station_ids].split(",")
        flag = 0
        wo_station_ids.each do |ws|
          wid,sid = ws.split("_")
          wo = WorkOrder.find_by_id(wid)
          station = Station.find_by_id(sid)
          if station.status != Station::STAT[:NORMAL]
            flag = 1
            status = 1
            msg = "#{station.name}异常，暂时无法服务!"
          else
            station_prods = StationServiceRelation.where(["station_id=?", station.id]).map(&:product_id) #获取要调换到的那个工位所支持的服务
            order = wo.order
            opr = order.order_prod_relations.map(&:product_id)
            serv_ids = Product.where(["is_service=? and id in (?)", Product::PROD_TYPES[:SERVICE], opr]).map(&:id)
            station_staffs = StationStaffRelation.load_relation(station.store_id,station.id)
            if station_prods & serv_ids != serv_ids
              flag = 1
              status = 1
              msg = "#{station.name}不支持该服务!"
            end
          end
        end
        if flag == 0
          order_stations = []
          wo_station_ids.each do |wo_station|
            wo_id,station_id = wo_station.split("_")
            wo = WorkOrder.find_by_id(wo_id)
            time = wo.cost_time.nil? ? 0 : wo.cost_time
            current_time = Time.now
            ended_at =   current_time + time*60
            status = wo && wo.update_attributes({:station_id=>station_id.to_i,:status=>WorkOrder::STAT[:SERVICING],:started_at => current_time, :ended_at => ended_at}) ? 0 : 1
            if status == 0
              order = wo.order
              station_staffs = StationStaffRelation.load_relation(order.store_id,station_id)
              order.update_attributes(:station_id => wo.station_id) if order
              TechOrder.where(:order_id=>order.id).delete_all
              staff_ids = station_staffs.map(&:staff_id)
              staff_ids.map {|staff_id|
                order_stations << TechOrder.new(:staff_id=>staff_id,:order_id=>order.id,:own_deduct=>order.technician_deduct/staff_ids.length)}
            end
          end
          TechOrder.import order_stations unless order_stations.blank?
        end
      end
      work_orders = working_orders params[:store_id]
    else
      status = 1
    end
    render :json => {:status => status, :msg => msg, :orders => work_orders}
  end


  def update_customer
    status = 0
#    begin
      customers = []
      Customer.transaction do
        car_parm = {:car_model_id => params[:brand].nil? || params[:brand].split("_")[1].nil? ? nil : params[:brand].split("_")[1].to_i,
          :buy_year =>  params[:year], :distance => params[:cdistance].nil? ? nil : params[:cdistance].to_i}
        customer_parm  = {:name => params[:userName].nil? ? nil : params[:userName].strip, :mobilephone => params[:phone].nil? ? nil : params[:phone].strip,
          :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i,
          :property => params[:cproperty].to_i, :group_name => params[:cproperty].to_i==0 ? nil : params[:cgroup_name]}
        if params[:c_id].to_i == -1 or params[:c_id].to_i == 0
          customers = Customer.where(:mobilephone=>params[:phone],:store_id=>params[:store_id],:status=>Customer::STATUS[:NOMAL]).select("id,name,group_name,address")
          if params[:c_id].to_i == -1 &&  customers.length >=1
            status = 2
          else
            customer = Customer.find_by_id_and_store_id(params[:customer_id].to_i,params[:store_id].to_i)
            car_num = CarNum.find_by_id(params[:car_num_id].to_i)
            car_num.update_attributes(car_parm)
            customer.update_attributes(customer_parm)
          end
        else #当选择已存在的客户时  需要修改订单归属 将车牌绑定到已选择客户
          customer = Customer.find_by_id_and_store_id(params[:c_id].to_i,params[:store_id].to_i)
          car_num = CarNum.find_by_id(params[:car_num_id].to_i)
          car_num.update_attributes(car_parm)
          customer.update_attributes(customer_parm)
          Order.where(:store_id=>params[:store_id].to_i,:customer_id=>params[:customer_id].to_i,:car_num_id=>car_num.id).update_all(:customer_id=>customer)
          CustomerNumRelation.where(:customer_id=>params[:customer_id],:car_num_id=>car_num.id).delete_all
          customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
          Reservation.where(:car_num_id=>car_num.id).update_all(:customer_id=>customer.id)
        end
      end
#    rescue
#      status = 1
#    end
    render :json => {:status => status,:customers=>customers}
  end


end
