#encoding: utf-8
class MonthScore < ActiveRecord::Base
  belongs_to :staff
  belongs_to :store
  GOAL_NAME ={0=>"服务类",1=>"产品类",2=>"卡类",3=>"其他"}
  IS_UPDATE = {:YES=>1,:NO=>0} # 1 更新 0 未更新


  def self.sort_order_date(store_id,created,ended)
    sql ="select date_format(o.created_at,'%Y-%m-%d') day,sum(op.price) price,op.pay_type  from orders o inner join order_pay_types op on
    o.id=op.order_id where store_id=#{store_id} and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]})
    and ifnull(is_free,0) !=#{Order::IS_FREE[:YES]} and o.sale_id is null and op.pay_type in (#{OrderPayType::PAY_TYPES.values[0..3].join(',')})"
    sql += " and date_format(o.created_at,'%Y-%m-%d')>='#{created}'" unless created.nil? || created =="" && created.length==0
    sql += " and date_format(o.created_at,'%Y-%m-%d')<='#{ended}'"   unless ended.nil? || ended =="" || ended.length==0
    sql += "group by date_format(o.created_at,'%Y-%m-%d'),op.pay_type order by o.created_at desc"
    return Order.find_by_sql(sql)
  end

  def self.kind_order(store_id)
    return Order.find_by_sql("select p.id,p.name,p.is_service,p.service_code,op.price,sum(op.pro_num) prod_num,sum(op.total_price) sum,date_format(op.created_at,'%Y-%m-%d')
    day,o.id o_id  from orders o inner join order_prod_relations op on o.id=op.order_id inner join products p on p.id=op.product_id where
    o.store_id=#{store_id} and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) group by p.id,date_format(o.created_at,'%Y-%m-%d') ")
  end   

  def self.search_kind_order(created,ended,time,store_id,is_service)
    sql ="select p.id,p.name,p.is_service,p.service_code,op.price,sum(op.pro_num) prod_num,sum(op.total_price) sum,"
    sql += "date_format(op.created_at,'%Y-%m-%d') day" if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql += "date_format(op.created_at,'%X-%V') day" if time.to_i==Sale::DISC_TIME[:WEEK]
    sql += "date_format(op.created_at,'%X-%m') day"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql +=" from products p inner join order_prod_relations op on p.id=op.product_id inner join orders o on o.id=op.order_id
     where o.store_id=#{store_id} and o.status in (#{Order::PRINT_CASH.join(',')}) and is_service=#{is_service} "
    sql += " and date_format(op.created_at,'%Y-%m-%d')>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and date_format(op.created_at,'%Y-%m-%d')<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql +=" group by p.id,date_format(op.created_at,'%Y-%m-%d')"  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by p.id,date_format(op.created_at,'%X-%V')"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by p.id,date_format(op.created_at,'%X-%m')"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql += " order by op.created_at desc"
    return Order.find_by_sql(sql)
  end


  def self.search_goals(store_id)
    return GoalSale.find_by_sql("select concat_ws('-',date_format(started_at,'%Y.%m.%d'),date_format(ended_at,'%Y.%m.%d')) day,
           type_name,goal_price,date_format(ended_at,'%Y-%m-%d') end_day,ended_at,current_price from goal_sales where store_id=#{store_id} group by id,
           concat_ws('-',date_format(started_at,'%Y.%m.%d'),date_format(ended_at,'%Y.%m.%d'))")
  end

  def self.normal_ids(ids,is_service,time=nil)
    sql ="select op.product_id,sum(op.price) price,op.order_id,"
    sql += "date_format(op.created_at,'%Y-%m-%d') day" if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql += "date_format(op.created_at,'%X-%V') day" if time.to_i==Sale::DISC_TIME[:WEEK]
    sql += "date_format(op.created_at,'%X-%m') day"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql +=" from order_pay_types op inner join orders o  on o.id=op.order_id inner join products p on p.id=op.product_id where product_id in (#{ids.uniq.join(",")}) and
       op.pay_type in (#{OrderPayType::PAY_TYPES[:DISCOUNT_CARD]},#{OrderPayType::PAY_TYPES[:PACJAGE_CARD]},#{OrderPayType::PAY_TYPES[:SALE]},#{OrderPayType::PAY_TYPES[:IS_FREE]})
     and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) and is_service=#{is_service}  "
    sql +=" group by date_format(op.created_at,'%Y-%m-%d'),product_id "  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by product_id,date_format(op.created_at,'%X-%V')"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by product_id,date_format(op.created_at,'%X-%m')"  if time.to_i==Sale::DISC_TIME[:MONTH]
    return OrderPayType.find_by_sql(sql)
  end

  def self.sort_pay_types(store_id,time=nil,created=nil,ended=nil)
    sql ="select op.product_id,sum(op.price) sum,op.order_id,sum(op.product_num) prod_num,pay_type,"
    sql += "date_format(op.created_at,'%Y-%m-%d') day" if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql += "date_format(op.created_at,'%X-%V') day" if time.to_i==Sale::DISC_TIME[:WEEK]
    sql += "date_format(op.created_at,'%X-%m') day"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql +=" from order_pay_types op inner  join orders o on o.id=op.order_id  where o.store_id=#{store_id} and
       pay_type in (#{OrderPayType::LOSS.join(',')}) and o.status in (#{Order::PRINT_CASH.join(',')}) "
    sql += " and date_format(op.created_at,'%Y-%m-%d')>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and date_format(op.created_at,'%Y-%m-%d')<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql +=" group by date_format(op.created_at,'%Y-%m-%d'),product_id,pay_type"  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by product_id,date_format(op.created_at,'%X-%V'),pay_type"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by product_id,date_format(op.created_at,'%X-%m'),pay_type"  if time.to_i==Sale::DISC_TIME[:MONTH]
    return OrderPayType.find_by_sql(sql) 
  end

  def self.prod_serv_pay_types()
    sql ="select op.product_id,sum(op.price) sum,op.order_id,sum(op.product_num) prod_num,pay_type,"
    sql += "date_format(op.created_at,'%Y-%m-%d') day" if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql += "date_format(op.created_at,'%X-%V') day" if time.to_i==Sale::DISC_TIME[:WEEK]
    sql += "date_format(op.created_at,'%X-%m') day"  if time.to_i==Sale::DISC_TIME[:MONTH]
    sql +=" from order_pay_types op inner  join orders o on o.id=op.order_id  where o.store_id=#{store_id} and
       pay_type in (#{OrderPayType::LOSS.join(',')}) and o.status in (#{Order::PRINT_CASH.join(',')}) "
    sql += " and date_format(op.created_at,'%Y-%m-%d')>='#{created}'" unless created.nil? || created =="" || created.length==0
    sql += " and date_format(op.created_at,'%Y-%m-%d')<='#{ended}'" unless ended.nil? || ended =="" || ended.length==0
    sql +=" group by date_format(op.created_at,'%Y-%m-%d'),product_id,pay_type"  if time.nil? || time.to_i==Sale::DISC_TIME[:DAY]
    sql +=" group by product_id,date_format(op.created_at,'%X-%V'),pay_type"  if time.to_i==Sale::DISC_TIME[:WEEK]
    sql +=" group by product_id,date_format(op.created_at,'%X-%m'),pay_type"  if time.to_i==Sale::DISC_TIME[:MONTH]
    return OrderPayType.find_by_sql(sql)
  end
  
end
