#encoding: utf-8
module ApplicationHelper
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'socket'
  include Constant
  include UserRoleHelper
  include Oauth2Helper
  include CustomersHelper
  include MessagesHelper
  include LoginsHelper
  include MessagesHelper

  MODEL_STATUS = {:NORMAL => 0,:DELETE =>1} #0 正常 1 删除
  def sign?
    deny_access unless signed_in?
  end

  def deny_access
    redirect_to "/logins"
  end

  def signed_in?
    return (cookies[:user_id] != nil and ((params[:store_id].nil? and @store.nil?) or current_user.store_id == params[:store_id].to_i or (@store and current_user.store_id == @store.id)))
  end

  def current_user
    return Staff.find_by_id(cookies[:user_id].to_i)
  end

  #客户管理提示信息
  def customer_tips
    @complaints = Complaint.find_by_sql(["select c.id, c.reason, c.suggestion, o.code, cu.name, ca.num, cu.id cu_id, o.id o_id
      from complaints c inner join orders o on o.id = c.order_id
      inner join customers cu on cu.id = c.customer_id inner join car_nums ca on ca.id = o.car_num_id 
      where c.store_id = ? and c.status = ? ", params[:store_id].to_i, Complaint::STATUS[:UNTREATED]])
    
    @notices = Customer.find_by_sql("select DISTINCT(c.id), c.name from customers c
      where c.status = #{Customer::STATUS[:NOMAL]} 
      and c.store_id in(#{StoreChainsRelation.return_chain_stores(params[:store_id].to_i).join(",")}) 
      and c.birthday is not null and
      ((month(now())*30 + day(now()))-(month(c.birthday)*30 + day(c.birthday))) between  -7
      and 0")
  end

  def staff_names
    names = []
    staffs = Staff.find_by_sql("select id,name from staffs where status = #{Staff::STATUS[:normal]}")
    idx = 0
    staffs.each do |staff|
      names[idx] = []
      names[idx] << "#{staff.name}" << staff.id
      idx+=1
    end
    names
  end

  def from_s store_id
    a = Item.new
    a.id = 0
    a.name = "总部"
    suppliers = [a] + Supplier.all(:select => "s.id,s.name", :from => "suppliers s",
      :conditions => "s.store_id=#{store_id} and s.status=0")
    suppliers
  end

  def cover_div controller_name
    return request.url.include?(controller_name) ? "hover" : ""
    #puts self.action_name,self.controller_path,self.controller,self.controller_name,request.url
  end

  def material_status status, type
    str = ""
    if type == 0
      if status == 0
        str = "未付款"
      elsif status == 1
        str = "已付款"
      elsif status == 4
        str = "已取消"
      end
    elsif type == 1
      if status == 0
        str = "未发货"
      elsif status == 1
        str = "已发货"
      elsif status == 2
        str = "已收货"
      elsif status == 3
        str = "已入库"
      elsif status == 4
        str = "已退货"
      end
    end
    str
  end

  def role_model relations,func_num,model_name
    check = false
    arr = []
    (relations || []).each do |relation|
      if relation && relation.model_name == model_name
        arr << relation
      end
    end
    (arr || []).each do |relation|
      if relation && relation.num == func_num
        check = true
        break
      end
    end
    check
  end

  def get_last_twelve_months
    months = []
    12.times do |i|
      months << DateTime.now.months_ago(i+1).strftime("%Y-%m")
    end
    months
  end

  def create_get_http(url,route)
    uri = URI.parse(URI.encode(url))
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.port==443
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(route)
    back_res = http.request(request)
    return JSON back_res.body
  end

  def satisfy
    orders = Order.find(:all, :select => "is_pleased", 
      :conditions => [" store_id = ? and status in (#{Order::STATUS[:BEEN_PAYMENT]}, #{Order::STATUS[:FINISHED]}) and 
       date_format(created_at,'%Y-%m-%d') >= ? and date_format(created_at,'%Y-%m-%d') <= ?",
        params[:store_id].to_i,Time.now.months_ago(1).beginning_of_month.strftime("%Y-%m-%d"), Time.now.months_ago(1).end_of_month.strftime("%Y-%m-%d")])
    un_pleased_size = 0
    orders.collect { |o| un_pleased_size += 1 if o.is_pleased == Order::IS_PLEASED[:BAD] }
    pleased = orders.size == 0 ? 0 : (orders.size - un_pleased_size)*100/orders.size
    unpleased = orders.size == 0 ? 0 : 100 - pleased
    return [pleased, unpleased]
  end

  def material_order_tips
    @material_pay_notices = Notice.find_all_by_store_id_and_types_and_status(params[:store_id].to_i,
      Notice::TYPES[:URGE_PAYMENT], Notice::STATUS[:NORMAL])
    @material_orders_received = MaterialOrder.where("m_status = ? and supplier_id = ? and store_id = ?", MaterialOrder::M_STATUS[:received], 0, params[:store_id])
    @material_orders_send = MaterialOrder.where("m_status = ? and supplier_id = ? and store_id = ?", MaterialOrder::M_STATUS[:send], 0, params[:store_id])
    store = Store.find_by_id(params[:store_id].to_i)
    @low_materials = Material.where(["status = ? and store_id = ? and storage <= material_low and is_ignore = ?", Material::STATUS[:NORMAL],
        store.id, Material::IS_IGNORE[:NO]]) if store
  end

  def random_file_name(file_name)
    name = File.basename(file_name)
    return (Digest::SHA1.hexdigest Time.now.to_s + name)[0..20]
  end

  def proof_code(len)
    chars = ('A'..'Z').to_a + ('a'..'z').to_a + (0..9).to_a
    code_array = []
    1.upto(len) {code_array << chars[rand(chars.length)]}
    return code_array.join("")
  end


  #物料
  def get_mo(material,material_orders)
    mos = {}
    material_orders.each do |material_order|
      mio_num = MatInOrder.where(:material_id => material.id, :material_order_id => material_order.id).sum(:material_num)
      moi_num = MatOrderItem.find_by_material_id_and_material_order_id(material.id, material_order.id).try(:material_num)
      if mio_num < moi_num
        mos[material_order] = moi_num - mio_num
      end
    end
    mos
  end



  #根据订单分组
  def order_by_status(orders)
    orders = orders.group_by{|order| order.status}
    #把免单的order放在已付款下面
    if orders[Order::STATUS[:FINISHED]].present?
      orders[Order::STATUS[:BEEN_PAYMENT]] ||= []
      orders[Order::STATUS[:BEEN_PAYMENT]] = (orders[Order::STATUS[:BEEN_PAYMENT]] << orders[Order::STATUS[:FINISHED]]).flatten
      orders.delete(Order::STATUS[:FINISHED])
    end
    orders
  end

  #新的app，order分组，把已付款，但是施工中的放在施工中
  def new_app_order_by_status(orders)
    order_hash = {}
    order_hash[Order::STATUS[:WAIT_PAYMENT]] = orders.select{|order| order.status == Order::STATUS[:WAIT_PAYMENT] || order.status == Order::STATUS[:PCARD_PAY]}
    order_hash[WorkOrder::STAT[:WAIT]] = orders.select{|order| order.wo_status == WorkOrder::STAT[:WAIT]}
    order_hash[WorkOrder::STAT[:SERVICING]] = orders.select{|order| order.wo_status == WorkOrder::STAT[:SERVICING]}
    s_staffs = TechOrder.joins(:staff,:order=>:work_orders).select("work_orders.station_id,staffs.name,tech_orders.staff_id").
      where(:"tech_orders.order_id"=>order_hash[WorkOrder::STAT[:SERVICING]].map(&:order_id),:"staffs.store_id"=>params[:store_id]).group_by{|i|i.station_id}.values
    order_hash[:used_staffs] = s_staffs
    order_hash
  end

  #
  def combin_orders(orders)
    work_orders = WorkOrder.where(:order_id=>orders.map(&:id)).inject({}){|h,w|h[w.order_id]=w;h}
    service_names = Order.joins(:order_prod_relations=>:product).where( :"orders.id"=>orders.map(&:id)).
      where("products.is_service=#{Product::PROD_TYPES[:SERVICE]} or is_added=#{Product::IS_ADDED[:YES]}").
      select("group_concat(products.name) service_name,orders.id order_id").group("orders.id").inject({}){|h,w|h[w.order_id]=w.service_name;h}
    orders.map{|order|
      work_order = work_orders[order.id]
      order[:wo_started_at] = (work_order && work_order.started_at && work_order.started_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:wo_ended_at] = (work_order && work_order.ended_at && work_order.ended_at.strftime("%Y-%m-%d %H:%M:%S")) || ""
      order[:car_num] = order.car_num.try(:num)
      order[:service_name] = service_names[order.id]
      order[:cost_time] = work_order.try(:cost_time)
      order[:station_id] = work_order.try(:station_id)
      order[:order_id] = order.try(:id)
      order[:c_pcard_relation_id] = order.try(:c_pcard_relation_id)
    }
    orders
  end


  def mkdir(dir_name,file_name)
    pwd = Constant::LOCAL_DIR
    date = Time.now.strftime("%Y-%m-%d")
    total_dir = [dir_name,date,""]
    total_dir.each_with_index do |dir,index|
      dir_path = "#{pwd}/"+total_dir[0..index].join("/")
      Dir.mkdir(dir_path)  unless File.directory?(dir_path)
    end
    "#{pwd}"+total_dir.join("/")+file_name+".txt"
  end

  def check_str(str)
    no_ch = str.gsub(/[\u4e00-\u9fa5]/,"").bytesize
    #    no_ch_en = str.gsub(/[\u4e00-\u9fa5]/,"").gsub(/[a-zA-z]/,"").bytesize
    return (str.bytesize-no_ch)+no_ch*1.5
  end

  def get_voilate_reward
    @violations = ViolationReward.joins(:staff).where(:status => false,:"staffs.store_id"=>params[:store_id])
    send_msg
  end

  def send_msg
    @send_msg = SendMessage.where(:store_id=>params[:store_id],:status=>[SendMessage::STATUS[:WAITING],SendMessage::STATUS[:FAIL]])
  end

  #保留金额的两位小数
  def limit_float(num)
    return num.nil? ? 0 : (num*100).to_i/100.0
  end

  def js_hash(hash)
    return hash.inject({}){|h,v|h["#{v[0]}"]="#{v[1]}";h}
  end

  #核对门店的客户账单
  def check_account(c_id,s_id,month)
    receipt = PayReceipt.where(:month=>month,:types=>Account::TYPES[:CUSTOMER],:supply_id=>c_id,:store_id=>s_id).select("ifnull(sum(amount),0) amount").first.amount
    p_price = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::FINCANCE_TYPES.keys,:pay_status=>OrderPayType::PAY_STATUS[:COMPLETE],
      :"orders.store_id"=>s_id,:"orders.customer_id"=>c_id).where("date_format(order_pay_types.updated_at,'%Y-%m')='#{month}'").select("ifnull(sum(order_pay_types.price),0) p_price").first.p_price
    return [receipt,p_price]
  end

  def create_code(len)
    chars =  (0..9).to_a
    code_array = []
    1.upto(len) {code_array << chars[rand(chars.length)]}
    return code_array.join("")
  end

  def add_string(len,str)
    return "0"*(len-"#{str}".length)+"#{str}"
  end

  def chain_store(store_id)  #获取本门店的连锁店
    sql ="select distinct(scr.store_id) from store_chains_relations scr inner join stores s on scr.store_id=s.id where s.status in
      (#{Store::STATUS[:OPENED]},#{Store::STATUS[:DECORATED]})  and scr.chain_id in (select distinct(scr.chain_id) from store_chains_relations scr
      inner join chains c on scr.chain_id=c.id where scr.store_id =#{store_id} and c.status=#{Chain::STATUS[:NORMAL]} )"
    stores = StoreChainsRelation.find_by_sql(sql).map(&:store_id) #获取该门店所有的连锁店
    stores.any? ? stores : [store_id]
  end
  


  def warn_account(percent,day,third_v)
    acc = third_v == [] ? [] : 0
    order_accounts = OrderPayType.joins(:order).where(:pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
      :"orders.store_id"=>params[:store_id]).select("ifnull(sum(order_pay_types.price),0) total_price,
      date_format(min(order_pay_types.created_at),'%Y-%m-%d') min_time,orders.customer_id").group("orders.customer_id")
    unless order_accounts.blank?
      customers = Customer.where(:id=>order_accounts.map(&:customer_id)).inject({}){|h,c|h[c.id]=c;h}
      order_accounts.each do |account|
        if customers[account.customer_id] and customers[account.customer_id].check_time
          if customers[account.customer_id].check_type == Customer::CHECK_TYPE[:MONTH]
            time = account.min_time.to_datetime+customers[account.customer_id].check_time.months-day.days
          else
            time = account.min_time.to_datetime+customers[account.customer_id].check_time.weeks-day.days
          end
          if  account.total_price >= customers[account.customer_id].debts_money*percent  or time.strftime("%Y-%m-%d") <= Time.now.strftime("%Y-%m-%d")
            if third_v == []
              acc << account
            elsif third_v ==0
              acc += 1
            end
          end
        end
      end
    end
    acc
  end


  def turn_js_hash(k_vs)
    hash ={}
    k_vs.each do |k,v|
      vs = {}
      v.each do |k1,v1|
        vs["#{k1}"] = "#{v1}"
      end
      hash["#{k}"]= "#{vs}"
    end
    return "#{hash}".gsub("=>",":")
  end

  #发送短信的功能
  def send_message_request(message_arr,send_num)
    times = message_arr.length%send_num == 0 ? message_arr.length/send_num-1 <0 ? 0 : message_arr.length/send_num-1 : message_arr.length/send_num
    response = []
    (0..times).each do |time|
      start_num = time*send_num
      end_num = (time+1)*send_num-1
      msg_hash = {:resend => 0, :list => message_arr[start_num..end_num] ,:size => message_arr[start_num..end_num].length}
      jsondata = JSON msg_hash
      message_route = "/send_packet.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&jsondata=#{jsondata}&Exno=0"
      response << create_get_http(Constant::MESSAGE_URL, message_route)
    end
    response
  end


  #统一发送短信的方式和相关数据  目前仅限于单条发送和费用的计算
  def message_data(store_id,send_message,customer,car_num,msg_types) #customer有时是staff
    store,m_msg = Store.find(store_id),""
    piece = send_message.length%70==0 ? send_message.length/70 : send_message.length/70+1
    this_price = piece*Constant::MSG_PRICE
    phone = customer.attributes["mobilephone"] ||= customer.attributes["phone"]
    if phone and (store.message_fee-this_price) >= Constant::OWE_PRICE
      status = SendMessage::STATUS[:FINISHED]
      m_parm = {:store_id =>store_id, :content =>send_message,:send_at => Time.now,:types=>msg_types}
      begin
        if store.send_list and store.send_list.split(",").include?("#{msg_types}")
          message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{phone}&Content=#{URI.escape(send_message)}&Exno=0"
          response = create_get_http(Constant::MESSAGE_URL, message_route)
          file_path = mkdir("send_logs","send_log")
          file = File.open(file_path,"a+")
          file.write("\r\n#{response}\r\n".force_encoding("UTF-8"))
          file.close
          if response["code"] == "9001"
            store.warn_store(this_price) #提示门店费用信息
            m_msg = "短信发送成功"
            m_parm.merge!({:total_num=>piece,:total_fee=>piece*Constant::MSG_PRICE})
          else
            m_msg = "短信发送失败"
            status = SendMessage::STATUS[:WAITING]
          end
        else
          m_msg = "短信功能已关闭，请手动发送，如需开通请到开关设置打开！"
          status = SendMessage::STATUS[:WAITING]
        end
      rescue
        #        status = SendMessage::STATUS[:WAITING]
        #        #      rescue Errno::ETIMEDOUT
        #        #      rescue EOFError
      end
      parms = {:customer_id=>customer.id,:car_num_id=>car_num,:phone=>phone,:store_id=>store_id,:status=>status}
      message_record = MessageRecord.create(m_parm.merge({:status=>status}))
      SendMessage.create(parms.merge({:content=>send_message,:types=>SendMessage::TYPES[:OTHER],
            :send_at=>Time.now.strftime('%Y-%m-%d %H:%M:%S'),:message_record_id => message_record.id}))
    else
      m_msg = "短信余额不足，未发送。。。"  #使用新的变量m_msg防止多次提醒
    end
    return m_msg
  end


  #统一发送短信的方式和相关数据  目前仅限于多条发送发送和费用的计算
  def multiple_message_data(store_id,m_arrs,msg_types,m_content) #customer有时是staff
    send_messages,store,m_msg,t_piece = [],Store.find(store_id),"",0
    status = SendMessage::STATUS[:WAITING]
    status = SendMessage::STATUS[:FINISHED]  if store.send_list and store.send_list.split(",").include?("#{msg_types}")
    message_record = MessageRecord.create(:store_id =>store_id, :content => m_content,:types=>msg_types,:status => status,:send_at => Time.now)
    m_arrs.each do |m_arr|
      content = URI.unescape(m_arr[:content])
      t_piece += content.length%70==0 ? content.length/70 : content.length/70+1
      send_messages << SendMessage.new(:message_record_id => message_record.id, :customer_id =>m_arr[:msid],:types=>SendMessage::TYPES[:OTHER],
        :content => content, :phone =>m_arr[:mobile],:send_at => Time.now, :status => status,:store_id=>store_id)
    end
    this_price = t_piece*Constant::MSG_PRICE
    if  (store.message_fee-this_price) >= Constant::OWE_PRICE
      begin
        if store.send_list and store.send_list.split(",").include?("#{msg_types}")
          send_num = 800/m_content.length
          response = send_message_request(m_arrs,send_num) #此处传递m_content用于计算大致的可发送条数
          file_path = mkdir("send_logs","send_log")
          file = File.open(file_path,"a+")
          file.write("\r\n#{response}\r\n".force_encoding("UTF-8"))
          file.close
          store.warn_store(this_price) #提示门店费用信息
          message_record.update_attributes({:total_num=>t_piece,:total_fee=>t_piece*Constant::MSG_PRICE})
          m_msg = "短信发送成功"
        else
          m_msg = "短信功能已关闭，请手动发送，如需开通请到开关设置打开！"
        end
        SendMessage.import send_messages unless send_messages.blank?
      rescue
         m_msg = "短信发送失败"
        status = SendMessage::STATUS[:WAITING]
      end
    else
      message_record.destroy
      m_msg = "短信余额不足，未发送。。。"  #使用新的变量防止多次提醒
    end
    return m_msg
  end

  def get_dir_list(path)   #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end

  # 中英文混合字符串截取
  def truncate_u(text, length = 30, truncate_string = "......")
    l=0
    char_array=text.unpack("U*")
    char_array.each_with_index do |c,i|
      l = l+ (c<127 ? 0.5 : 1)
      if l>=length
        return char_array[0..i].pack("U*")+(i<char_array.length-1 ? truncate_string : "")
      end
    end
    return text
  end

  
end

