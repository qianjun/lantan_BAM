#encoding: utf-8
class WorkOrdersController < ApplicationController
  def work_orders_status
    now_date = Time.now.strftime("%Y%m%d").to_i   #获取当前日期时间
    current_info = {} #哈希：一个门店的数据（等待付款、工位信息（工位名称、状态、技师、正在施工车牌、剩余时间、等待施工车牌、剩余时间））
    wait_pay_car_nums,normal_station = [],[] #定义数组存放所有待付款车牌
    stations = Station.this_store(params[:store_id]).can_show.select("name,status,id").order("id")    #查询所有未删除的工位
    cons_staffs = Station.joins(:station_staff_relations => :staff).select("stations.id s_id,staffs.name staff_name").where(
      :station_staff_relations =>{:store_id=>params[:store_id]}).group_by{|i|i.s_id} #查询所有当天的技师
    #查询所有工单对应的车牌号等信息
    work_orders = WorkOrder.joins(:station,:order=>:car_num).select("num car_num,work_orders.status work_order_status,
           TIMESTAMPDIFF(minute,now(),work_orders.ended_at) time_left,orders.id oid,work_orders.created_at wo_updated_at,
           stations.status s_status,stations.id station_id").where(:work_orders=>{:store_id=>params[:store_id],:current_day=>now_date}).
      where(:"orders.status"=>Order::CASH).order("work_orders.started_at asc").group_by{|i|i.station_id}
    oprs = OrderProdRelation.joins(:product).where(:order_id=>work_orders.values.flatten.map(&:oid).compact.uniq).
      select("products.name,order_id").group_by{|i|i.order_id}
    stations.each do |station| #遍历所有工位

      station[:cons_staffs] = cons_staffs[station.id].nil? ? nil : cons_staffs[station.id].map(&:staff_name)       #为该工位加入技师信息
     
      station[:dealing_car_num],station[:s_name],station[:dealing_time_left] = nil,nil,nil  #如果没有正在施工的车辆，则正在施工的车牌、剩余时间为空
      work_orders[station.id].each do |work_order|
        # STAT = {:WAIT=>0,:SERVICING=>1,:WAIT_PAY=>2,:COMPLETE=>3}
        if work_order.work_order_status == WorkOrder::STAT[:SERVICING]  #正在施工的车牌号,剩余时间及服务项目名称
          station[:dealing_car_num] = work_order.car_num
          station[:dealing_time_left] = work_order.time_left
          station[:dealing_time_left] = 0 if station[:dealing_time_left].to_i  < 0
          station[:s_name] = oprs[work_order.oid].nil? ? nil : oprs[work_order.oid].inject([]){|a, o| a << o.name;a}.join(",")
        elsif work_order.work_order_status == WorkOrder::STAT[:WAIT_PAY]   #等待付款车牌号
          wait_pay_car_nums << work_order.car_num
        end
      end if work_orders[station.id]
      normal_station << station    if station.status == Station::STAT[:NORMAL]
    end unless stations.blank? # if station.status == Station::STAT[:NORMAL] 结束标记

    current_info[:wait_pay_car_nums] = wait_pay_car_nums.length == 0 ? nil : (wait_pay_car_nums-stations.map(&:dealing_car_num)).compact.uniq
    current_info[:station_infos] = normal_station.blank? ? nil : normal_station
    #查出所有总部的有效的活动
    hs = Sale.find_by_sql(["SELECT s.img_url,'#{Constant::HEAD_OFFICE_API_PATH.chop}' c_path from lantan_store.sales s where s.status=? and
           ((s.disc_time_types in (?)) or (s.disc_time_types=? and DATE_FORMAT(s.ended_at,'%Y-%m-%d')>=DATE_FORMAT(NOW(),'%Y-%m-%d')))#",
        Sale::STATUS[:RELEASE],Sale::TOTAL_DISC,Sale::DISC_TIME[:TIME]])

    hs << Sale.find_by_sql(["SELECT s.img_url,'#{Constant::SERVER_PATH.chop}' c_path from sales s where s.status=? and s.store_id=? and
       ((s.disc_time_types in (?)) or (s.disc_time_types=? and DATE_FORMAT(s.ended_at,'%Y-%m-%d')>=DATE_FORMAT(NOW(),'%Y-%m-%d')))",
        Sale::STATUS[:RELEASE],params[:store_id].to_i,Sale::TOTAL_DISC,Sale::DISC_TIME[:TIME]])
    local_sales = hs.flatten.inject([]){|h, s|
      h << s.c_path + s.img_url unless s.img_url.nil? || s.img_url.strip == "";
      h
    }
    wait_serving = Order.joins([:work_orders,:car_num]).select("num").where("work_orders.current_day =? and work_orders.store_id = ? and work_orders.status != ? and work_orders.station_id is null", now_date, params[:store_id], WorkOrder::STAT[:CANCELED]).map(&:num).uniq
    current_info[:no_station_wos] = wait_serving - wait_pay_car_nums
    current_info[:local_sales] = local_sales.flatten
    render :json => current_info
  end

  def login
    staff = Staff.find(:first, :conditions => ["username = ? and status in (?)",params[:user_name], Staff::VALID_STATUS])
    store = staff.store if staff
    info = ""
    if  store.nil? or staff.nil? or !staff.has_password?(params[:user_password])
      info = "用户名或密码错误"
      status = 2
    elsif store.status != Store::STATUS[:OPENED]
      info = "#{store.close_reason}"
      status = 1
    else
      status = 0
      stations_count = Station.where("store_id =? and status not in (?) ",staff.store_id, [Station::STAT[:WRONG], Station::STAT[:DELETED]]).count
    end
    render :json => {:store_id => staff.present? ? staff.store_id : 0, :status => status, :stations_count => stations_count || 0,:info=>info}
  end

end
