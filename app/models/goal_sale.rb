#encoding: utf-8
class GoalSale < ActiveRecord::Base
  belongs_to :store
  has_many :goal_sale_types
  TYPES_NAMES = {0 =>"产品",1 =>"服务",2 =>"卡",3 =>"其他"}
  TYPES = {:PRODUCT =>0,:SERVICE =>1,:CARD =>2,:OTHER =>3}

  #选取目前销售额当前的最大分类编号
  def self.max_type(store_id)
    return GoalSaleType.find_by_sql("select max(types) max from goal_sale_types t inner join goal_sales g on t.goal_sale_id=g.id
    where g.store_id=#{store_id} ")[0]
  end

  #查询所有的分类
  def self.total_type(store_id,time)
    sql = "select s.id,s.ended_at,s.started_at,t.type_name,t.goal_price,t.current_price from goal_sales s
    inner join goal_sale_types t on t.goal_sale_id=s.id where s.store_id=#{store_id} and "
    sql += "date_format(ended_at,'%Y-%m-%d')<date_format(now(),'%Y-%m-%d')" if time==1
    sql += "date_format(ended_at,'%Y-%m-%d')>=date_format(now(),'%Y-%m-%d')" if time==0
    return GoalSaleType.find_by_sql(sql)
  end

  #更新每天的销售报表
  def self.update_curr_price(store_id)
    sql ="select sum(op.total_price) sum,p.is_service,p.types,p.id p_id,o.id  from orders o inner join order_prod_relations op on o.id=op.order_id
     inner join products p on p.id=op.product_id where date_format(o.created_at,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d') and o.store_id=#{store_id}
     and o.status in (#{Order::STATUS[:BEEN_PAYMENT]},#{Order::STATUS[:FINISHED]}) group by p.id"
    pays =Order.find_by_sql(sql)
    price={}
    unless pays.blank?
      pay_sql = "select sum(price) price,product_id p_id from order_pay_types  where product_id in (#{pays.map(&:p_id).uniq.join(",")}) and
    pay_type in (#{OrderPayType::PAY_TYPES[:DISCOUNT_CARD]},#{OrderPayType::PAY_TYPES[:PACJAGE_CARD]},#{OrderPayType::PAY_TYPES[:SALE]},#{OrderPayType::PAY_TYPES[:IS_FREE]}) and
    date_format(created_at,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d') group by product_id"
      prices = OrderPayType.find_by_sql(pay_sql).inject(Hash.new){|hash,prod|hash[prod.p_id].nil? ? hash[prod.p_id]= prod.price : hash[prod.p_id] += prod.price;hash}
      pro_price = pays.inject(Hash.new){|hash,pay|hash[pay.p_id] =(pay.sum.nil? ? 0 : pay.sum)-(prices[pay.p_id].nil? ? 0 : prices[pay.p_id]);hash}
      orders = pays.inject(Hash.new){|hash,order|hash[order.types].nil? ? hash[order.types]= [order] : hash[order.types] << [order];hash}
      price =orders.select {|key,value| key!=Product::TYPES_NAME[:OTHER_PROD] && key!=Product::TYPES_NAME[:OTHER_SERV] }.values.flatten.inject(Hash.new){|hash,order|
        hash[order.is_service].nil? ? hash[order.is_service]= pro_price[order.p_id] : hash[order.is_service] += pro_price[order.p_id];hash}
      price.merge!(GoalSale::TYPES[:OTHER]=>orders.select {|key,value|
          key==Product::TYPES_NAME[:OTHER_PROD] || key==Product::TYPES_NAME[:OTHER_SERV] }.values.flatten.inject(0){|num,order| num+= pro_price[order.p_id]})
    end
    car_price =CPcardRelation.find_by_sql("select sum(c.price) sum_price from c_pcard_relations c inner join package_cards p on p.id=c.package_card_id
      where p.store_id=#{store_id} and date_format(c.created_at,'%Y-%m-%d')=date_format(now(),'%Y-%m-%d')")[0]
    price.merge!(GoalSale::TYPES[:CARD]=>car_price.sum_price.to_i)
    return price
  end


end
