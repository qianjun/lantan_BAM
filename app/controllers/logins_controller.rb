#encoding: utf-8
require "uri"
class LoginsController < ApplicationController
  def index
    #if cookies[:user_id]
    #@staff = Staff.find_by_id(cookies[:user_id].to_i)
    #if @staff.nil?
    #render :index, :layout => false
    #else
    #session_role(cookies[:user_id])
    #if has_authority?
    #redirect_to "/stores/#{@staff.store_id}/welcomes"
    #else
    #render :index, :layout => false
    #end
    #end
    #else
    render :index, :layout => false
    #end
    
  end

  def create
    @staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:user_name], Staff::VALID_STATUS])
    store = @staff.store if @staff
    if @staff.nil?  or store.nil?  or !@staff.has_password?(params[:user_password])
      flash.now[:notice] = "用户名或密码错误"
      #redirect_to "/"
      @user_name = params[:user_name]
      render 'index', :layout => false
    elsif  store.status != Store::STATUS[:OPENED]
      flash.now[:notice] = "#{store.close_reason}"
      @user_name = params[:user_name]
      render 'index', :layout => false
    else
      if @staff.status != Staff::STATUS[:normal]
        @user_name = params[:user_name]
        render 'index', :layout => false
      else
        file_path = mkdir("login_ip_logs","ip_log")
        file = File.open(file_path,"a+")
        ip = request.headers["HTTP_X_REAL_IP"] || request.remote_ip
        info = create_get_http("http://ip.taobao.com","/service/getIpInfo.php?ip=#{ip}")["data"]
        position = "#{info["country"]}-#{info["area"]}-#{info["region"]}-#{info["city"]}--#{info["isp"]}"
        p city = store.city

        region = City.find store.city.parent_id if store.city.parent_id != 0
        if @staff.name =~ /管理员/ || city.name =~ /#{info["city"]+"-"+info["region"]}/ || (region && region.name =~ /#{info["region"]}/  )
          file.write("\r\n登录ip:#{ip}-- 时间#{Time.now.strftime('%Y-%m-%d %H:%M:%S')}  登录用户：#{@staff.name} 门店ID:#{@staff.store_id}  门店地址：#{store.address}  所属区域：#{position} \r\n".force_encoding("UTF-8"))
          file.close
          @staff.update_attributes(:last_login=>Time.now.strftime("%Y-%m-%d %H:%M:%S"))
          cookies[:user_id]={:value =>@staff.id, :path => "/", :secure  => false}
          cookies[:user_name]={:value =>@staff.name, :path => "/", :secure  => false}
          session_role(cookies[:user_id])
          flash.now[:notice] = "为系统安全，请修改密码！" if @staff.has_password?(@staff.phone)
          #if has_authority?
          redirect_to "/stores/#{@staff.store_id}/welcomes"
        else
          flash.now[:notice] = "登录区域有误，请核实后重新尝试！"
          @user_name = params[:user_name]
          render 'index', :layout => false
        end
      end
      #else
      #  cookies.delete(:user_id)
      #  cookies.delete(:user_name)
      #  cookies.delete(:user_roles)
      #  cookies.delete(:model_role)
      #  flash[:notice] = "抱歉，您没有访问权限"
      #  redirect_to "/"
      #end
    end
  end

  def logout
    cookies.delete(:user_id)
    cookies.delete(:user_name)
    cookies.delete(:user_roles)
    cookies.delete(:model_role)
    cookies.delete(:store_name)
    cookies.delete(:store_id)
    redirect_to root_path
  end

  def forgot_password
    staff = Staff.where("phone = '#{params[:telphone]}' and validate_code = '#{params[:validate_code]}'").
      where("status in (?)", Staff::VALID_STATUS).first
    if staff && !params[:validate_code].nil? && !params[:validate_code].blank?
      random_password = [*100000..999999].sample
      content = "您当前修改后的密码是#{random_password}，请妥善保管。"
      MessageRecord.transaction do
        #        begin
        @notice = message_data(staff.store_id,content,staff,nil,MessageRecord::M_TYPES[:CHANGE_PWD])
        #        rescue
        #          @notice = "短信通道忙碌，请稍后重试。"
        #        end
        staff.password = random_password
        staff.validate_code = nil
        staff.encrypt_password
        staff.save
        @flag = true
      end
    else
      @notice = "手机号，验证码不正确"
    end
  end

  def send_validate_code
    #staff = Staff.find_by_phone(params[:telphone])
    staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:telphone], Staff::VALID_STATUS])
    if staff
      random_num = [*100000..999999].sample
      content = "您本次的验证码#{random_num}，请尽快修改您的登陆密码。"
      MessageRecord.transaction do
        #        begin
        @notice = message_data(staff.store_id,content,staff,nil,MessageRecord::M_TYPES[:CHANGE_PWD])
        staff.update_attribute(:validate_code, random_num)
        render :text => "success"
        #        rescue
        #          render :text => "短信通道忙碌，请稍后重试。"
        #        end
      end
    else
      render :text => "手机号码不存在!"
    end
  end

  def phone_login
    render :layout=>nil
  end

  def manage_content
    if cookies[:phone_store].nil?
      redirect_to "/phone_login"
    else
      @store = Store.find(cookies[:phone_store])
      if @store && cookies[:phone_store].to_i == @store.id
        session[:time] = (session[:time].nil? || session[:time] != Time.now.strftime("%Y-%m-%d %H")) ?  Time.now.strftime("%Y-%m-%d %H") :  session[:time]
        @orders = Order.joins("inner join order_prod_relations op on op.order_id=orders.id inner join products p on p.id=op.product_id").
          select("sum(op.pro_num*op.price) num,date_format(orders.created_at,'%Y-%m-%d') day,is_service").where(:status=>[Order::STATUS[:BEEN_PAYMENT],Order::STATUS[:FINISHED]]).
          where("date_format(orders.created_at,'%Y-%m-%d') >= '#{Time.now.beginning_of_month.strftime('%Y-%m-%d')}' and date_format(orders.created_at,'%Y-%m-%d %H') <= '#{session[:time]}'
          and orders.store_id=#{@store.id} and (orders.is_free =#{Order::IS_FREE[:NO]} or orders.is_free is null) and orders.sale_id is null").group("date_format(orders.created_at,'%Y-%m-%d'),is_service").inject(Hash.new){
          |hash,order| hash[order.day].nil? ? hash[order.day]={order.is_service => order.num} : hash[order.day][order.is_service]=order.num;hash}
        weeks = @orders.select{|k,v| k>= Time.now.beginning_of_week.strftime('%Y-%m-%d')}
        @total_week = weeks == {} ? {0=>0,1=>0} : weeks.values.inject(Hash.new){|hash,total|total.each{|k,v|
            hash[k].nil? ? hash[k]=v : hash[k] += v};hash}
        @total_month = @orders == {} ? {0=>0,1=>0} : @orders.values.inject(Hash.new){|hash,total|
          total.each{|k,v| hash[k].nil? ? hash[k]=v : hash[k] += v};hash}
        render :layout=>nil
      else
        redirect_to "/phone_login"
      end
    end
  end

  def login_phone
    @staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:login_name], Staff::VALID_STATUS])
    if  @staff.nil? or !@staff.has_password?(params[:login_pwd])
      flash.now[:notice] = "用户名或密码错误"
      @user_name = params[:login_name]
      msg =0
    elsif @staff.store.nil? || @staff.store.status != Store::STATUS[:OPENED]
      flash.now[:notice] = "用户不存在"
      @user_name = params[:login_name]
      msg = 0
    else
      cookies[:phone_id] ={:value =>@staff.id, :path => "/", :secure  => false}
      cookies[:phone_store]={:value =>@staff.store_id, :path => "/", :secure  => false}
      msg = 1
    end
    render :json=> {:msg=>msg}
  end

end