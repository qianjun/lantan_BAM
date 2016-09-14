#encoding: utf-8
class StaffManagesController < ApplicationController
  before_filter :sign?
  layout "complaint"

  before_filter :get_store

  def index
    @staffs = Staff.where("store_id = #{params[:store_id]}").
      paginate(:per_page => Constant::PER_PAGE, :page => params[:page] ||= 1)
  end


  def show
    @staff = Staff.find_by_id(params[:id])
    year = Time.now.strftime("%Y")
    base_sql = get_base_sql(year)
    chart_image = ChartImage.where("types = #{ChartImage::TYPES[:STAFF_LEVEL]}").
                  where("staff_id = #{@staff.id}").
                  where(base_sql).
                  where("store_id = #{@store.id}").
                  order("created_at desc").first
    @chart_url = chart_image.image_url unless chart_image.nil?
    respond_to do |format|
      format.js
    end
  end

  def get_year_staff_hart
    @staff = Staff.find_by_id(params[:id])
    year = params[:year]
    base_sql = get_base_sql(year)
    chart_image = ChartImage.where("types = #{ChartImage::TYPES[:STAFF_LEVEL]}").
                  where("staff_id = #{@staff.id}").
                  where(base_sql).
                  where("store_id = #{params[:store_id]}").
                  order("created_at desc").first
    chart_url = chart_image.nil? ? "no data" : chart_image.image_url
    render :text => chart_url
  end

  def average_score_hart
    @year = params[:year] ||= Time.now.strftime("%Y")
    base_sql = get_base_sql(@year)
    technician_chart_image = ChartImage.where(base_sql).
                            where("types = #{ChartImage::TYPES[:MECHINE_LEVEL]}").
                            where("store_id = #{params[:store_id]}").
                            order('created_at desc').first
    @avg_technician = technician_chart_image.image_url unless technician_chart_image.nil?

    front_chart_image = ChartImage.where(base_sql).
                        where("types = #{ChartImage::TYPES[:FRONT_LEVEL]}").
                        where("store_id = #{params[:store_id]}").
                        order('created_at desc').first
    @avg_front = front_chart_image.image_url unless front_chart_image.nil?
  end

  def get_base_sql(year)
    if year == Time.now.strftime("%Y")
      month = Time.now.months_ago(1).strftime("%m")
      base_sql = "current_day >= '#{year}-#{month}-01 00:00:00' and date_format(current_day,'%Y-%m-%d') <= '#{year}-#{month}-31'"
    else
      base_sql = "current_day >= '#{year}-12-01 00:00:00' and date_format(current_day,'%Y-%m-%d') <= '#{year}-12-31'"
    end
    return base_sql
  end

  def average_cost_detail_summary  #平均成本明细汇总
    @services = Product.is_service.is_normal.where("store_id=#{@store.id}")
    @started_time = params[:search_s_time].nil?||params[:search_s_time].empty? ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:search_s_time]
    @ended_time = params[:search_e_time].nil?||params[:search_e_time].empty? ? Time.now.strftime("%Y-%m-%d") : params[:search_e_time]
    search_sql = "select o.id oid, opr.pro_num oprpnum, pmr.material_num pmrmnum, m.id mid, m.price mprice
                  from orders o 
                  inner join order_prod_relations opr on o.id=opr.order_id
                  inner join products p on p.id=opr.product_id
                  inner join prod_mat_relations pmr on pmr.product_id=p.id
                  inner join materials m on m.id=pmr.material_id
                  where o.store_id=#{@store.id}
                  and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]})
                  and p.is_service=#{Product::PROD_TYPES[:SERVICE]}
                  and date_format(o.created_at, '%Y-%m-%d')>='#{@started_time}'
                  and date_format(o.created_at, '%Y-%m-%d')<'#{@ended_time}'"
    @type = params[:search_s_type]
    unless params[:search_s_type].nil? || params[:search_s_type].to_i == 0
      search_sql += " and p.id=#{params[:search_s_type].to_i}"
    end
    total = Order.find_by_sql(search_sql)
    total_cost = 0   
    total.each do |t|
      total_cost += t.oprpnum*t.pmrmnum*t.mprice
    end
    @total_cost = total_cost #标准成本
    @total_num = total.map(&:oid).uniq.length  #服务车辆总数
    mid = total.map(&:mid).uniq.join(",")
    actual_search_sql = "select moo.material_num mmnum , m.id mid, m.name mname,m.price mprice
                                      from mat_out_orders moo
                                      inner join materials m on m.id=moo.material_id
                                      where moo.types=#{MatOutOrder::TYPES_VALUE[:cost]}
                                      and moo.store_id=#{@store.id}
                                      and date_format(moo.created_at, '%Y-%m-%d')>='#{@started_time}'
                                      and date_format(moo.created_at, '%Y-%m-%d')<'#{@ended_time}'"
   actual = []
   if mid && !mid.blank?
     actual_search_sql += " and m.id in (#{mid})"
     actual = MatOutOrder.find_by_sql(actual_search_sql)
   end
   actual_cost = 0
   actual.each do |at|
     actual_cost += at.mmnum*at.mprice
   end if !actual.blank?
   @actual_cost = actual_cost #实际成本
   hash = actual.group_by{|a|a.mid} unless actual.blank?
   total_array = []
   hash.each do |k, v|
     a = 0
     b = v[0].mname
     c = v[0].mprice
     v.each do |obj|
       a += obj.mmnum
     end
     total_array << k.to_s + "," + a.to_s + "," + b.to_s + "," + c.to_s
   end if hash
   @total_array = total_array
   respond_to do |f|
     f.html
     f.js
   end
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end
