#encoding: utf-8
class MessagesController < ApplicationController
  before_filter :sign?, :except => ["alipay_compete","wechat_msg"]
  layout "customer"
  respond_to :html, :xml, :json
  @@m = Mutex.new
  require 'will_paginate/array'
  
  def index
    session[:started_at] = nil
    session[:ended_at] = nil
    session[:is_vip] = nil
    session[:is_visited] = nil
    session[:is_birthday] = nil
    session[:is_time] = "1"
    session[:time] = nil
    session[:is_price] = "1"
    session[:price] = nil
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_message_customers(@store.id, (Time.now - 15.days).to_date.to_s, Time.now.to_date.to_s, nil, "1",
      "3", "1", "500", nil, nil)
  end

  def search
    session[:started_at] = params[:started_at]
    session[:ended_at] = params[:ended_at]
    session[:is_vip] = params[:is_vip]
    if params[:is_visited] == "-1" or params[:is_visited] == "0" or params[:is_visited] == "1"
      session[:is_visited] = params[:is_visited]
      session[:is_birthday] = nil
    elsif params[:is_visited] == "2"
      session[:is_visited] = nil
      session[:is_birthday] = params[:is_visited]
    end
    session[:is_time] = params[:is_time]
    session[:time] = params[:time]
    session[:is_price] = params[:is_price]
    session[:price] = params[:price]
    redirect_to "/stores/#{params[:store_id]}/messages/search_list"
  end

  def search_list
    @store = Store.find(params[:store_id].to_i)
    @customers = Order.get_message_customers(@store.id, session[:started_at], session[:ended_at], session[:is_visited],
      session[:is_time], session[:time], session[:is_price], session[:price], session[:is_vip], session[:is_birthday])
    render "index"
  end

  def create
    unless params[:content].strip.empty? or params[:customer_ids].nil?
      MessageRecord.transaction do
        begin
          customers = Customer.find_all_by_id(params[:customer_ids].split(","))
          message_arr = []
          customers.each do |customer|
            if customer.mobilephone && customer.name
              c_name = "#{customer.name}先生/小姐"
              content = params[:content].strip.gsub("%name%",c_name).gsub(" ", "")
              message_arr << {:content => URI.escape(content), :msid => "#{customer.id}", :mobile => customer.mobilephone}
            end
          end
          flash[:notice] = multiple_message_data(params[:store_id],message_arr,MessageRecord::M_TYPES[:PACK_MSG],params[:content])
        rescue
          flash[:notice] = "短信通道忙碌，请稍后重试。"
        end
      end
    end
    redirect_to "/stores/#{params[:store_id]}/messages/search_list"
  end

  def send_list
    store = Store.find(params[:store_id])
    @send_list = store.send_list.nil? ? [] : store.send_list.split(",")
    render :layout=>"role"
  end

  def set_message
    store = Store.find(params[:store_id])
    send_list = store.send_list.nil? ? [] : store.send_list.split(",")
    if params[:m_status] and params[:m_index]
      if params[:m_status].to_i == 0
        send_list.delete(params[:m_index])
        store.update_attribute(:send_list,send_list.join(","))
      else
        store.update_attribute(:send_list,(send_list << params[:m_index]).uniq.compact.join(","))
      end
    end
    render :json=>{:message=>params[:m_fun]}
  end
  
  def send_detailed
    @start_time = params[:first_time].nil? || params[:first_time] == "" ? (Time.now - Constant::PRE_DAY.days).strftime("%Y-%m-%d") : params[:first_time]
    @end_time = params[:last_time].nil? || params[:last_time] == "" ? Time.now.strftime("%Y-%m-%d") : params[:last_time]
    sql = "date_format(send_at,'%Y-%m-%d')>='#{@start_time}' and date_format(send_at,'%Y-%m-%d')<='#{@end_time}' "
    sql +=  (params[:types] and params[:types] != "") ? " and types=#{params[:types]} and status=#{MessageRecord::STATUS[:SENDED]}" : " and status=#{MessageRecord::STATUS[:SENDED]}"
    @message_records =  MessageRecord.where(:store_id=>params[:store_id]).where(sql).order("created_at desc").paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @total_num = MessageRecord.where(:store_id=>params[:store_id]).where(sql).sum("total_fee")
    render :layout=>"role"
  end


  def load_message
    @message_record = MessageRecord.find(params[:id])
    @m_records = MessageRecord.where(:store_id=>@message_record.store_id).
      where("date_format(send_at,'%Y-%m-%d') between '#{(@message_record.send_at-8.days).strftime('%Y-%m-%d')}' and '#{ (@message_record.send_at+8.days).strftime('%Y-%m-%d')}' ")
    @send_message = SendMessage.where(:send_messages=>{:status=>SendMessage::STATUS[:FINISHED],:message_record_id=>@m_records.map(&:id)}).select("*").group_by{|i|i.message_record_id}
    render :layout=>nil
  end

  def send_alipay
    sql = "select * from alipay_records where store_id=#{params[:store_id]}"
    @alipay_messages = AlipayRecord.paginate_by_sql(sql, :page => params[:page], :per_page =>Constant::PER_PAGE)
    @store = Store.find params[:store_id]
    render :layout=>"role"
  end

  
  #发送充值请求
  def alipay_charge
    options ={
      :service=>"create_direct_pay_by_user",
      :notify_url=>Constant::SERVER_PATH+"stores/#{params[:store_id]}/messages/alipay_compete",
      :subject=>"短信充值费用#{params[:pay_fee]}元",
      :payment_type=>MessageRecord::PAY_TYPES[:ALIPAY],
      :return_url=>Constant::SERVER_PATH+"stores/#{params[:store_id]}/messages/send_alipay",
      :total_fee=>params[:pay_fee]
    }
    out_trade_no="#{params[:store_id]}_#{Time.now.strftime("%Y%m%d%H%M%S")}"+create_code(6)
    options.merge!(:seller_email =>Constant::SELLER_EMAIL, :partner =>Constant::PARTNER, :_input_charset=>"utf-8", :out_trade_no=>out_trade_no)
    options.merge!(:sign_type => "MD5", :sign =>Digest::MD5.hexdigest(options.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Constant::PARTNER_KEY))
    redirect_to "#{Constant::PAGE_WAY}?#{options.sort.map{|k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
  end

  #充值异步回调
  def alipay_compete
    out_trade_no = params[:out_trade_no]
    trade_nu = out_trade_no.to_s.split("_")
    order = AlipayRecord.find(:first, :conditions => ["out_trade_no=?",params[:out_trade_no]])
    if order.nil?
      alipay_notify_url = "#{Constant::NOTIFY_URL}?partner=#{Constant::PARTNER}&notify_id=#{params[:notify_id]}"
      response_txt =Net::HTTP.get(URI.parse(alipay_notify_url))
      my_params = Hash.new
      request.parameters.each {|key,value|my_params[key.to_s]=value}
      my_params.delete("action")
      my_params.delete("controller")
      my_params.delete("sign")
      my_params.delete("sign_type")
      my_params.delete("store_id")
      mysign = Digest::MD5.hexdigest(my_params.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Constant::PARTNER_KEY)
      dir = "#{Rails.root}/public/logs"
      Dir.mkdir(dir)  unless File.directory?(dir)
      file_path = dir+"/alipay_#{Time.now.strftime("%Y%m%d")}.log"
      if File.exists? file_path
        file = File.open( file_path,"a")
      else
        file = File.new(file_path, "w")
      end
      file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{request.parameters.to_s}\r\n"
      file.close
      if mysign ==params[:sign] and response_txt=="true"
        if params[:trade_status]=="WAIT_BUYER_PAY"
          render :text=>"success"
        elsif params[:trade_status]=="TRADE_FINISHED" or params[:trade_status]=="TRADE_SUCCESS"
          @@m.synchronize {
            begin
              AlipayRecord.transaction do
                store = Store.find trade_nu[0]
                AlipayRecord.create(:store_id=>trade_nu[0],:pay_types=>MessageRecord::PAY_TYPES[:ALIPAY],:pay_price=>params[:total_fee],
                  :out_trade_no=>"#{params[:out_trade_no]}",:pay_status=>AlipayRecord::STATUS[:NORMAL],:pay_email=>params[:buyer_email],
                  :left_price=>store.message_fee+params[:total_fee].to_f.round(2),:pay_userid=>params[:buyer_id])
                store.update_attributes({:message_fee=>(store.message_fee+params[:total_fee].to_f).round(2),:owe_warn=>Constant::OWE_WARN[:NONE]}) #更新
                Log.delete_all(:store_types=>store.id)
              end
              render :text=>"success"
            rescue
              render :text=>"success"
            end
          }
        else
          render :text=>"fail" + "<br>"
        end
      else
        redirect_to "/"
      end
    else
      render :text=>"success"
    end
  end

  #微信发送短信的接口
  def wechat_msg
    begin
      content = "尊敬的用户您好,您的本次活动验证码为:#{params[:code]}"
      customer = Customer.where(:name=>"微信用户").where("store_id is null").first
      if customer
        customer.update_attribute(:mobilephone,params[:phone])
      else
        customer = Customer.create(:name=>"微信用户",:mobilephone=>params[:phone])
      end
      msg = message_data(params[:store_id],content,customer,nil,MessageRecord::M_TYPES[:WECHAT])
      status = 1
    rescue
      msg = "加载失败，稍候重试"
      status = 0
    end
    render :json=>{:msg =>msg,:status =>status}
  end
  
end
