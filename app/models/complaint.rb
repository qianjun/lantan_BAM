#encoding: utf-8
class Complaint < ActiveRecord::Base
  has_many :revisits 
  belongs_to :order
  belongs_to :customer
  belongs_to :store
  has_many :store_complaints
  has_many :store_pleasants
  require 'rubygems'
  require 'google_chart'
  require 'net/https'
  require 'uri'
  require 'open-uri'

  #投诉类型
  TYPES = {:CONSTRUCTION => 0, :SERVICE => 1, :PRODUCTION => 2, :INSTALLATION => 3, :ACCIDENT => 4, :OTHERS => 5, :INVALID => 6}
  TIMELY_DAY = 2 #及时解决的标准
  TYPES_NAMES = {0 => "施工质量", 1 => "服务质量", 2 => "产品质量", 3 => "门店设施", 4 => "意外事件", 5 => "其他", 6 => "无效投诉"}

  #投诉状态
  STATUS = {:UNTREATED => 0, :PROCESSED => 1} #0 未处理  1 已处理
  STATUS_NAME ={0 =>"未处理",1 =>"已处理"}
  VIOLATE = {:NORMAL=>1,:INVALID=>0} #0  不纳入  1 纳入
  VIOLATE_N = {true=>"是",false=>"否"}
  SEX = {:MALE =>1,:FEMALE =>0,:NONE=>2} # 0 未选择 1 男 2 女


  def self.one_customer_complaint(store_id, customer_id, per_page, page)
    return Complaint.paginate_by_sql(["select c.id c_id, c.created_at, c.reason, c.suggestion, c.types, c.status, c.remark,
         o.code, o.id o_id from complaints c left join orders o on o.id = c.order_id  where c.store_id = ? and c.customer_id = ? ", store_id, customer_id],
      :per_page => per_page, :page => page)
  end
  
  def self.show_types(store_id,created,ended,sex,name=nil)
    sql = "select count(c.id) total_num,c.types from complaints c inner join customers s on c.customer_id=s.id where c.store_id=?
      and c.status=? "
    conditions = ["",store_id,Complaint::STATUS[:PROCESSED]]
    unless created.nil? || created =="" || created.length==0
      sql += "and date_format(c.created_at,'%Y-%m-%d')>= ? "
      conditions << created
    end
    unless ended.nil? || ended =="" || ended.length==0
      sql += " and date_format(c.created_at,'%Y-%m-%d')<=?"
      conditions << ended
    end
    unless sex.to_i==2
      sql += " and s.sex=?"
      conditions << sex
    end
    unless name.nil? || name =="" || name.length==0
      sql += " and s.name like ?"
      conditions << "%#{name.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    sql += " group by c.types"
    conditions[0] = sql
    return  Complaint.find_by_sql(conditions).inject(Hash.new) {|panel,complaint| panel[complaint.types]=complaint.total_num;panel}
    
  end

  def self.count_types(store_id)
    return Complaint.find_by_sql("select count(*) total_num,types from complaints where store_id=#{store_id} and 
    date_format(created_at,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') and status=#{Complaint::STATUS[:PROCESSED]}  group by types")
  end
  
  def self.gchart(store_id)
    begin
      coplaint = Complaint.count_types(store_id).inject(Hash.new) {|panel,complaint| panel[complaint.types]=complaint.total_num;panel}
      month = Complaint.get_chart(store_id)
      unless coplaint.keys.blank?
        size =(0..10).inject(Array.new){|arr,int| arr << (coplaint.values.max%10==0 ? coplaint.values.max/10 : coplaint.values.max/10+1)*int} #生成图表的y的坐标
        GoogleChart::BarChart.new('1000x300', "#{Time.now.months_ago(1).strftime('%Y-%m')}投诉情况分类表", :vertical, false) do |bc|
          bc.data "Trend 2", coplaint.values, 'ff0000'
          bc.width_spacing_options :bar_width => 15, :bar_spacing => (1000-(15*coplaint.keys.length))/coplaint.keys.length,
            :group_spacing =>(1000-(15*coplaint.keys.length))/coplaint.keys.length
          bc.max_value size.max
          bc.axis :x, :labels => coplaint.keys.inject(Array.new) {|pal,key| pal << Complaint::TYPES_NAMES[key] }
          bc.axis :y, :labels =>size
          bc.grid :x_step => 3.333, :y_step => 10, :length_segment => 1, :length_blank => 3
          img_url = write_img(URI.escape(URI.unescape(bc.to_url)),store_id,ChartImage::TYPES[:COMPLAINT],store_id)
          month=ChartImage.create({:store_id=>store_id,:types =>ChartImage::TYPES[:COMPLAINT],:created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1)}) if month.blank?
        end
      end
    rescue
    end
    return month
  end

  def self.get_chart(store_id)
    return ChartImage.first(:conditions=>"store_id=#{store_id} and
   date_format(current_day,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m') and types=#{ChartImage::TYPES[:COMPLAINT]}")
  end

  def self.search_lis(store_id,created_at)
    sql ="select * from chart_images where store_id=#{store_id} and types=#{ChartImage::TYPES[:COMPLAINT]}"
    sql += " and date_format(current_day,'%Y-%m')='#{created_at}' order by created_at desc"  unless created_at.nil? || created_at=="" || created_at.length==0
    return ChartImage.find_by_sql(sql)[0]
  end


  def self.degree_chart(store_id)
    begin
      month = Complaint.count_pleasant(store_id)
      sql="select count(*) num,is_pleased,month(created_at) day from orders where date_format(created_at,'%Y-%m') < date_format(now(),'%Y-%m') 
      and store_id=#{store_id} and status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and date_format(created_at,'%Y')=date_format(now(),'%Y') group by month(created_at),is_pleased"
      orders =Order.find_by_sql(sql).inject(Hash.new){|hash,pleased|
        hash[pleased.day].nil? ? hash[pleased.day]={pleased.is_pleased=>pleased.num} : hash[pleased.day].merge!({pleased.is_pleased=>pleased.num});hash}
      unless orders=={}
        percent ={}
        orders.each {|k,order| percent[k]=(order.select{|k,v|  k != Order::IS_PLEASED[:BAD]}=={} ? 0 : order.select{|k,v|  k != Order::IS_PLEASED[:BAD]}.values.inject(0){|num,level| num+level}*100)/(order.values.inject(0){|num,level| num+level})}
        lc = GoogleChart::LineChart.new('1000x300', "满意度月度统计表", true)
        lc.data "满意度",percent.inject(Array.new){|arr,o|arr << [o[0]-1,o[1]]} , 'ff0000'
        size =(0..10).inject(Array.new){|arr,int| arr << 10*int} #生成图表的y的坐标
        lc.max_value [orders.keys.length-1,100]
        lc.axis :x, :labels =>orders.keys.inject(Array.new){|arr,mon|arr << "#{mon}月"}
        lc.axis :y, :labels => size
        lc.grid :x_step => 3.333, :y_step => 10, :length_segment => 1, :length_blank => 3
        img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),store_id,ChartImage::TYPES[:SATIFY],store_id)
        month = ChartImage.create({:store_id=>store_id,:types =>ChartImage::TYPES[:SATIFY],:created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1)})  if month.blank?
      end
    rescue
    end
    return month
  end

  def self.count_pleasant(store_id)
    return ChartImage.first(:conditions=>"store_id=#{store_id} and types=#{ChartImage::TYPES[:SATIFY]} and
   date_format(current_day,'%Y-%m')=date_format(DATE_SUB(curdate(), INTERVAL 1 MONTH),'%Y-%m')")
  end

  def self.degree_lis(store_id,created_at)
    sql ="select * from chart_images where store_id=#{store_id} and types=#{ChartImage::TYPES[:SATIFY]}"
    sql += " and date_format(current_day,'%Y-%m')='#{created_at}' order by created_at desc"  unless created_at.nil? || created_at=="" || created_at.length==0
    return ChartImage.find_by_sql(sql)[0]
  end


  def self.degree_day(store_id,created,ended,sex,c_name=nil)
    sql="select count(*) num,is_pleased from orders o inner join customers c on c.id=o.customer_id where 
      o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and o.store_id=? "
    conditions =["",store_id]
    unless created.nil? || created =="" || created.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')>=?"
      conditions << created
    end
    unless ended.nil? || ended =="" || ended.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')<=?"
      conditions << ended
    end
    unless sex.to_i==2
      sql += " and c.sex=?"
      conditions << sex
    end
    unless c_name.nil? || c_name =="" || c_name.length==0
      sql += " and c.name like ?"
      conditions << "%#{c_name}%"
    end
    sql += " group by is_pleased"
    conditions[0] = sql
    orders =Order.find_by_sql(conditions).inject(Hash.new){|hash,order| hash[order.is_pleased].nil? ? hash[order.is_pleased]=order.num : hash[order.is_pleased] +=order.num;hash}
    return orders=={} ? nil : orders.select{|k,v|  k != Order::IS_PLEASED[:BAD]}=={} ? 0 :
      orders.select{|k,v|  k != Order::IS_PLEASED[:BAD]}.values.inject(0){|num,level| num+level}*100/(orders.values.inject(0){|num,level| num+level})
  end
  
  def self.search_detail(store_id,created,ended)
    sql ="select c.*,o.code,o.id o_id,timestampdiff(minute,c.created_at,c.process_at) diff_time,c.process_at from complaints c inner join orders o on o.id=c.order_id  where c.store_id=#{store_id} "
    sql += " and date_format(c.created_at,'%Y-%m-%d')>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and date_format(c.created_at,'%Y-%m-%d')<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql += " order by c.created_at desc"
    return Complaint.find_by_sql(sql)
  end

  def self.mk_record(store_id ,order_id,reason,request,is_pleased)
    Order.transaction do
      order = Order.find_by_id order_id
      order.update_attribute("is_pleased", is_pleased)
      complaint = Complaint.create(:order_id => order_id, :customer_id => order.customer_id, :reason => reason,
        :suggestion => request, :status => STATUS[:UNTREATED], :store_id => store_id, 
        :code => Complaint.make_code(store_id)) if order
      complaint
    end
  end

  def self.write_img(url,store_id,types,object_id)  #上传图片
    file_name ="#{Time.now.strftime("%Y%m").to_s}_#{object_id}.jpg"
    dir = "#{File.expand_path(Rails.root)}/public/chart_images"
    Dir.mkdir(dir) unless File.directory?(dir)
    total_dir ="#{dir}/#{store_id}/"
    Dir.mkdir(total_dir) unless File.directory?(total_dir)
    all_dir ="#{total_dir}/#{types}/"
    Dir.mkdir(all_dir) unless File.directory?(all_dir)
    file_url ="#{all_dir}#{file_name}"
    open(url) do |fin|
      File.open(file_url, "wb+") do |fout|
        while buf = fin.read(1024) do
          fout.write buf
        end
      end
    end
    return "/chart_images/#{store_id}/#{types}/#{file_name}"
    puts "Chart #{object_id} success generated"
  end

  def self.consumer_types(store_id,sear,created=nil,ended=nil,sex=nil,car_model=nil,year=nil,name=nil,price=nil)
    sql = "select o.created_at,o.code,m.name,n.buy_year,o.id,o.price from orders o inner join customers c on c.id=o.customer_id inner join
    car_nums n on o.car_num_id=n.id inner join car_models m on m.id=n.car_model_id where o.store_id=? and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) "
    conditions = ["",store_id]
    unless created.nil? || created =="" || created.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')>=?" 
      conditions << created
    end
    unless ended.nil? || ended =="" || ended.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')<=?"
      conditions << ended
    end
    unless sex.nil? || sex =="" || sex.length==0
      sql += " and c.sex=?"
      conditions << sex
    end
    unless car_model.nil? || car_model =="" || car_model.length==0
      sql += " and m.id=?"
      conditions << car_model
    end
    unless year.nil? || year =="" || year.length==0
      sql += " and n.buy_year = ?"
      conditions << year
    end
    unless name.nil? || name =="" || name.length==0
      sql += " and c.name=?"
      conditions << name
    end
    sql += " and #{price}" unless price.nil? || price =="" || price.length==0
    sql += " and TO_DAYS(NOW())-TO_DAYS(o.created_at)<=15 "   if sear == 1
    sql += " order by created_at desc"
    conditions[0] = sql
    return Order.find_by_sql(conditions)
  end

  def self.consumer_t(store_id,sear,created=nil,ended=nil,sex=nil,car_model=nil,year=nil,name=nil,price=nil)
    sql = "select o.created_at,o.code,m.name,n.buy_year,o.id,o.price from orders o inner join customers c on c.id=o.customer_id inner join
    car_nums n on o.car_num_id=n.id inner join car_models m on m.id=n.car_model_id  where o.store_id=? and o.id in (#{sear.uniq.join(",")})
    and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) "
    conditions = ["",store_id]
    unless created.nil? || created =="" || created.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')>= ? "
      conditions << created
    end
    unless ended.nil? || ended =="" || ended.length==0
      sql += " and date_format(o.created_at,'%Y-%m-%d')<=?"
      conditions << ended
    end
    unless sex.nil? || sex =="" || sex.length==0
      sql += " and c.sex=?"
      conditions << sex
    end
    unless car_model.nil? || car_model =="" || car_model.length==0
      sql += " and m.id=?"
      conditions << car_model
    end
    unless year.nil? || year =="" || year.length==0
      sql += " and n.buy_year =?"
      conditions << year
    end
    unless name.nil? || name =="" || name.length==0
      sql += " and c.name=?"
      conditions << name
    end
    sql += " and #{price}" unless price.nil? || price =="" || price.length==0
    sql += " order by created_at desc"
    conditions[0] = sql
    return Order.find_by_sql(conditions)
  end

  def self.make_code store_id
    store = store_id.to_s
    if store_id.to_i < 10
      store =   "00" + store_id.to_s
    elsif store_id.to_i < 100
      store =    "0" + store_id.to_s
    end
    code = store + Time.now.strftime("%Y%m%d%H%M%S")
    return code
  end

end
