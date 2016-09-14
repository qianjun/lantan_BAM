#encoding: utf-8
class Order < ActiveRecord::Base
  has_many :order_prod_relations
  #  has_many :products, :through => :order_prod_relations
  has_many :order_pay_types
  has_many :work_orders
  belongs_to :car_num
  has_many :c_pcard_relations
  has_many :c_svc_relations
  belongs_to :customer
  belongs_to :sale
  has_many :revisit_order_relations
  has_many :o_pcard_relations
  has_many :complaints
  has_many :tech_orders
  has_many :return_orders
  has_many :mat_out_orders

  IS_VISITED = {:YES => 1, :NO => 0} #1 已访问  0 未访问
  STATUS = {:NORMAL => 0, :SERVICING => 1, :WAIT_PAYMENT => 2, :BEEN_PAYMENT => 3, :FINISHED => 4, :DELETED => 5, :INNORMAL => 6,
    :RETURN => 7, :COMMIT => 8, :PCARD_PAY => 9}
  STATUS_NAME = {0 => "等待中", 1 => "服务中", 2 => "等待付款", 3 => "已经付款", 4 => "免单", 5 => "已删除" , 6 => "未分配工位",
    7 =>"取消订单", 8 => "已确认，未付款(后台付款)", 9 => "套餐卡下单,等待付款"}
  #0 正常未进行  1 服务中  2 等待付款  3 已经付款  4 已结束  5已删除  6未分配工位 7 取消订单
  CASH =[STATUS[:NORMAL],STATUS[:SERVICING],STATUS[:WAIT_PAYMENT],STATUS[:COMMIT]]
  OVER_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED],STATUS[:RETURN]]
  PRINT_CASH = [STATUS[:BEEN_PAYMENT],STATUS[:FINISHED]]
  IS_FREE = {:YES=>1,:NO=>0} # 1免单 0 不免单
  TYPES = {:SERVICE => 0, :PRODUCT => 1,:DISCOUNT =>2,:SAVE =>3} #0 服务  1 产品
  FREE_TYPE = {:ORDER_FREE =>"免单",:PCARD =>"套餐卡使用"}
  #是否满意
  IS_PLEASED = {:BAD => 0, :SOSO => 1, :GOOD => 2, :VERY_GOOD => 3}  #0 不满意  1 一般  2 好  3 很好
  IS_PLEASED_NAME = {0 => "不满意", 1 => "一般", 2 => "好", 3 => "很好"}
  VALID_STATUS = [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]]
  O_RETURN = {:WASTE => 0, :REUSE => 1}  #  退单时 0 为报损 1 为回库
  DIRECT = {0=>"报损", 1=>"回库"}
  IS_RETURN = {:YES =>2,:NO =>0,:PART =>1} #0  成功交易  1部分退单 2 全部退单
  RETURN = {0 =>"成功交易" ,1=>"部分退单", 2 => "全部退单"}
  RETURN_TYPES = {:SAVE =>0,:CASH =>1,:PCARD =>2}
  REUTR_NAME = {0 =>"退到储值卡",1 =>"现金",2 =>"退到套餐卡"}

  #组装查询order的sql语句
  def self.generate_order_sql(started_at, ended_at, is_visited)
    condition_sql = ""
    params_arr = [""]
    unless started_at.nil? or started_at.strip.empty?
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      condition_sql += " and o.created_at <= ? "
      params_arr << ended_at.strip.to_date + 1.days
    end
    unless is_visited.nil? or is_visited == "-1"
      condition_sql += " and o.is_visited = ? "
      params_arr << is_visited.to_i
    end
    return [condition_sql, params_arr]
  end

  #获取需要回访的订单
  def self.get_revisit_orders(store_id, started_at, ended_at, is_visited, is_time, time, is_price, price)
    base_sql = "select distinct(o.customer_id) from orders o
      where o.store_id = #{store_id.to_i} and o.status in (#{STATUS[:BEEN_PAYMENT]}, #{STATUS[:FINISHED]}) "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    group_by_sql = ""

    if !is_time.nil? and !time.nil? and !time.strip.empty?
      group_by_sql += " group by o.customer_id having count(o.id) >= ? "
      params_arr << time.to_i
    end
    if !is_price.nil? and !price.nil? and !price.strip.empty?
      group_by_sql == "" ? group_by_sql = " group by o.customer_id having sum(o.price) >= ? " :
        group_by_sql += " or sum(o.price) >= ? "
      params_arr << price.to_i
    end
    params_arr[0] = base_sql + condition_sql + group_by_sql
    return Order.find_by_sql(params_arr).collect{ |i| i.customer_id }
  end

  #组装查询customer的sql
  def self.generate_customer_sql(condition_sql, params_arr, store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql = condition_sql
    customer_params_arr = params_arr.collect { |p| p }
    unless is_vip.nil? or is_vip == "-1"
      customer_condition_sql += " and cu.is_vip = ? "
      customer_params_arr << is_vip.to_i
    end
    unless is_birthday.nil?
      customer_condition_sql += " and ((month(now())*30 + day(now()))-(month(cu.birthday)*30 + day(cu.birthday))) <= 0
        and ((month(now())*30 + day(now()))-(month(cu.birthday)*30 + day(cu.birthday))) > -7 "
    end
    customer_ids = self.get_revisit_orders(store_id, started_at, ended_at, nil, is_time, time, is_price, price)
    unless customer_ids.nil? or customer_ids.blank?
      customer_condition_sql += " and cu.id in (?) "
      customer_params_arr << customer_ids
    end
    return [customer_params_arr, customer_condition_sql, customer_ids]
  end

  #根据需要回访的订单列出客户
  def self.get_order_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price, 
      price, is_vip, is_birthday, page)
    customer_sql = "select cu.id cu_id, cu.name, cu.mobilephone, cn.num, o.code, o.id o_id from customers cu
      inner join orders o on o.customer_id = cu.id left join car_nums cn on cn.id = o.car_num_id
      where cu.status = #{Customer::STATUS[:NOMAL]} and o.store_id = #{store_id.to_i} and cu.store_id = #{store_id.to_i}
      and o.status in (#{STATUS[:BEEN_PAYMENT]}, #{STATUS[:FINISHED]}) "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    customer_condition_sql = self.generate_customer_sql(condition_sql, params_arr, store_id, started_at,
      ended_at, is_visited, is_vip, is_time, time, is_price, price, is_birthday)
    customer_condition_sql[0][0] = customer_sql + customer_condition_sql[1]
    return customer_condition_sql[2].blank? ? [] :
      Customer.paginate_by_sql(customer_condition_sql[0], :per_page => 10, :page => page)
  end

  #查询需要发短信的用户
  def self.get_message_customers(store_id, started_at, ended_at, is_visited, is_time, time, is_price,
      price, is_vip, is_birthday)
    customer_sql = "select DISTINCT(cu.id) cu_id, cu.name from customers cu
      inner join orders o on o.customer_id = cu.id 
      where cu.status = #{Customer::STATUS[:NOMAL]} and cu.store_id = #{store_id.to_i} and LENGTH(TRIM(cu.name))>=1
     and LENGTH(TRIM(cu.mobilephone))=11 and o.store_id = #{store_id.to_i} and o.status in (#{STATUS[:BEEN_PAYMENT]}, #{STATUS[:FINISHED]}) "
    condition_sql = self.generate_order_sql(started_at, ended_at, is_visited)[0]
    params_arr = self.generate_order_sql(started_at, ended_at, is_visited)[1]
    customer_condition_sql = self.generate_customer_sql(condition_sql, params_arr, store_id, started_at, ended_at, is_visited,
      is_vip, is_time, time, is_price, price, is_birthday)
    condition_arr = customer_condition_sql[0]
    condition_sql = customer_condition_sql[1]
    condition_arr[0] = customer_sql + condition_sql
    return customer_condition_sql[2].blank? ? [] : Customer.find_by_sql(condition_arr)
  end

  def self.one_customer_orders(status, store_id, customer_id)
    @orders = Order.find_by_sql(["select * from orders where status in (#{status}) and store_id = ? and customer_id = ?
        order by created_at desc",  store_id, customer_id])
  end

  #正在进行中的订单
  def self.working_orders store_id
    #wo_status不在（2,3,4,5）o.status 在（0,1,2,3,4）
    return Order.find_by_sql(["select o.id, c.num, o.status, wo.id wo_id, wo.status wo_status,o.c_pcard_relation_id from orders o inner join car_nums c on c.id=o.car_num_id
      inner join customers cu on cu.id=o.customer_id left join work_orders wo on wo.order_id = o.id
     and wo.status not in (#{WorkOrder::STAT[:COMPLETE]},#{WorkOrder::STAT[:CANCELED]}, #{WorkOrder::STAT[:END]})
      where o.status not in (#{STATUS[:DELETED]}, #{STATUS[:INNORMAL]}, #{STATUS[:RETURN]})
      and DATE_FORMAT(o.created_at, '%Y%m%d')=DATE_FORMAT(NOW(), '%Y%m%d') and cu.status=? and o.store_id = ? order by o.status", Customer::STATUS[:NOMAL], store_id])
  end

  def self.search_by_car_num store_id,car_num, car_id
    customer = nil
    working_orders = []
    old_orders = []
    customer = CarNum.get_customer_info_by_carnum(store_id, car_num)
    if customer.present?
      orders = Order.includes(:order_pay_types).find_by_sql("select * from orders o where o.car_num_id=#{customer.car_num_id}
        and o.status!=#{STATUS[:DELETED]} and o.status != #{STATUS[:INNORMAL]} and o.store_id=#{store_id} order by o.created_at desc")
      #订单中购买的套餐卡
      package_cards = CPcardRelation.find_by_sql(["select cpr.order_id, pc.name, pc.price from c_pcard_relations cpr
            inner join package_cards pc
            on pc.id = cpr.package_card_id where cpr.order_id in (?)", orders]).group_by { |pc| pc.order_id }
      csvc_relations = CSvcRelation.includes(:sv_card).where(:order_id => orders.map(&:id)).group_by { |pc| pc.order_id }
      order_prod_relations = OrderProdRelation.includes(:product).where(:order_id => orders.map(&:id)).group_by { |pc| pc.order_id }
      order_pay_types = OrderPayType.where(:order_id => orders.map(&:id)).group_by{|opt| opt.order_id}
      staffs = Order.find_by_sql(["SELECT o.id, s.name FROM orders o inner join staffs s on o.front_staff_id = s.id where o.id in (?) and s.store_id = ?", orders, store_id]).group_by{|o| o.id}
      (orders || []).each do |order|
        order_hash = order
        #每个订单中的产品
        order_hash[:products] = []
        order_prod_relations[order.id].each do |opr|
          product = opr.product
          order_hash[:products] << {:name => product.name, :price => opr.price.to_f * opr.pro_num.to_i} if product
        end if order_prod_relations.present? && order_prod_relations[order.id].present?
        
        #每个订单中的储值卡、打折卡
        csvc_relations[order.id].each do |csvc_r|
          sv_card = csvc_r.sv_card
          sv_price =  sv_card.sale_price
          order_hash[:products] << {:name => sv_card.try(:name), :price => sv_price}
        end if csvc_relations.present? && csvc_relations[order.id].present?
        
        #每个订单中的套餐卡
        package_cards[order.id].each do |o_pc|
          order_hash[:products] << {:name => o_pc.name, :price => o_pc.price}
        end if package_cards.present? && package_cards[order.id].present?
        
        #订单对应的付款方式
        order_hash[:pay_type] = order_pay_types[order.id].collect{|type|
          OrderPayType::PAY_TYPES_NAME[type.pay_type]
        }.join(",") unless order_pay_types[order.id].nil?
        
        front_staff = staffs[order.id][0]
        order_hash[:staff] = front_staff.name if front_staff

        if order.status == STATUS[:BEEN_PAYMENT] or order.status == STATUS[:FINISHED]
          old_orders << order_hash  #过往订单
        else
          if (car_id && car_id.to_i == order.id) || car_id.nil?
            working_orders << order_hash  #进行中的订单
          end
        end
      end
      working_orders = working_orders.first if working_orders.size > 0
      customer_record = Customer.find_by_id(customer.customer_id)
      c_pcard_relations =  customer_record.pc_card_records_method(store_id)[1]  #套餐卡记录
      already_used_count = customer_record.pc_card_records_method(store_id)[0]

      pcard_records = []
      c_pcard_relations.each do |cpr|
        pc_record_hash ={}
        pc_record_hash[:is_expired] = (cpr.ended_at and cpr.ended_at < Time.now) ? 1 : 0
        pc_record_hash[:ended_at] = cpr.ended_at.strftime("%Y-%m-%d %H:%M:%S") if cpr.ended_at
        pc_record_hash[:name] = cpr.name
        pc_record_hash[:cpard_relation_id] = cpr.cpr_id
        pc_record_hash[:id] = cpr.id
        pc_record_hash[:has_p_card] = 1
        pc_record_hash[:products] = []
        cpr.content.split(",").each do |p_num|    
          prod_arr = p_num.split("-")
          prod_mat_relation = ProdMatRelation.find_by_sql(["select distinct(pmr.product_id)
      p_id, p.sale_price,p.is_service, m.storage m_storage from prod_mat_relations pmr
      inner join materials m on m.id = pmr.material_id inner join products p on p.id = pmr.product_id 
      where m.status = #{Material::STATUS[:NORMAL]} and p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and
      p.status = #{Product::IS_VALIDATE[:YES]} and p.id = ? and m.storage > 0 and m.store_id = ? group by p_id", prod_arr[0], store_id])[0]        
          service = Product.where(:status =>Product::IS_VALIDATE[:YES], :is_service => Product::PROD_TYPES[:SERVICE],
            :id => prod_arr[0])[0]
          price = prod_mat_relation.nil? ? service.try(:sale_price) : prod_mat_relation.try(:sale_price)
          unless prod_mat_relation.nil? && service.nil?
            prod_num = {}
            prod_num[:name] = prod_arr[1]
            prod_num[:id] = prod_arr[0]
            prod_num[:selected] = 1
            prod_num[:price] = price
            prod_num[:mat_num] = prod_mat_relation.m_storage if prod_mat_relation
            prod_num[:useNum] = already_used_count[cpr.cpr_id][prod_arr[0].to_i][1] if already_used_count && already_used_count[cpr.cpr_id] && already_used_count[cpr.cpr_id][prod_arr[0].to_i]
            prod_num[:leftNum] = prod_arr[2]
            pc_record_hash[:products] << prod_num
          end
        end
        pcard_records << pc_record_hash
      end
      #      sv_cards = SvcardUseRecord.joins(:c_svc_relation=>:sv_card).select("sv_cards.name sname,sv_cards.id sid,
      #    svcard_use_records.content,svcard_use_records.use_price,svcard_use_records.left_price,
      #    date_format(svcard_use_records.created_at,'%Y.%m.%d') created_at#").where("sv_cards.store_id=#{store_id} and
      #   c_svc_relations.customer_id=#{customer.customer_id}#").where(:types=>SvcardUseRecord::TYPES[:OUT]).group_by{|sc|sc.sid}
      sv_cards = CSvcRelation.find_by_sql(["select s.name sname, csr.sv_card_id sid, csr.id cid, sur.content, sur.use_price, sur.left_price,
          date_format(sur.created_at, '%Y.%m.%d') created_at from c_svc_relations csr inner join sv_cards s on
          csr.sv_card_id=s.id left join svcard_use_records sur on csr.id=sur.c_svc_relation_id and sur.types=? where
          s.store_id=? and s.types=? and csr.customer_id=? and csr.status=?", SvcardUseRecord::TYPES[:OUT], store_id,
          SvCard::FAVOR[:SAVE],customer.customer_id, CSvcRelation::STATUS[:valid]]).group_by{|sc|sc.cid}
      svcards_records = []
      sv_cards.each do |k, v|
        a = {}
        b = []
        a[:id] = v[0].sid
        a[:cid] = k
        a[:name] = v[0].sname
        v.each do |obj|
          c = {}
          c[:content] = obj.content
          c[:time] = obj.created_at.nil? || obj.created_at=="" ? "" : obj.created_at.strftime("%Y.%m.%d")
          c[:u_price] = obj.use_price
          c[:l_price] = obj.left_price
          b << c
        end
        a[:records] = b
        svcards_records << a
      end
    end
    [customer, working_orders, old_orders, pcard_records,svcards_records]
  end

  def self.get_brands_products store_id
    arr = {}
    capitals = Capital.all
    brands = CarBrand.all.group_by { |cb| cb.capital_id }
    capital_arr = []
    car_models = CarModel.all.group_by { |cm| cm.car_brand_id  }
    (capitals || []).each do |capital|
      c = capital
      brand_arr = []
      c_brands = brands[capital.id] unless brands.empty? and brands[capital.id]
      (c_brands || []).each do |brand|
        b = brand
        b[:models] = car_models[brand.id] unless car_models.empty? and car_models[brand.id] #brand.car_models
        brand_arr << b
      end
      c[:brands] = brand_arr
      capital_arr << c
    end    
    arr[:car_info] = capital_arr
    product_arr = {}
    clean_and_beauty_service_arr, maint_service_arr, clean_and_besuty_prod_arr, decorate_prod_arr, assis_prod_arr, elec_prod_arr, other_prod_arr = [], [], [], [], [], [], [], []
    prod_mat_relations = Product.find_by_sql(["select distinct(pmr.product_id) p_id, sum(m.storage) m_storage from prod_mat_relations pmr
      inner join materials m on m.id = pmr.material_id where m.status = #{Material::STATUS[:NORMAL]}
      and m.storage > 0 and m.store_id = ? group by p_id", store_id])
    p_ids = prod_mat_relations.inject({}){|pmr_h, pmr| pmr_h[pmr.p_id] = pmr.m_storage.to_i; pmr_h} if prod_mat_relations.any?

    products = Product.find_by_sql(["select * from products p where p.status = ?
      and p.id in (?) and p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and p.store_id = ?",
        Product::IS_VALIDATE[:YES], p_ids.keys.flatten, store_id]) if p_ids
    services = Product.find_by_sql(["select * from products p where p.status = ?
      and p.is_service = #{Product::PROD_TYPES[:SERVICE]} and p.show_on_ipad = ? and p.store_id = ?",
        Product::IS_VALIDATE[:YES], Product::SHOW_ON_IPAD[:YES], store_id])
    (((products||[]) + services) || []).each do |p|
      h = Hash.new
      h[:id] = p.id
      h[:name] = p.name
      h[:price] = p.sale_price
      h[:description] = p.description
      h[:mat_num] =  p_ids[p.id] if p.is_service == false
      h[:point] = p.prod_point
      h[:img] = (p.img_url.nil? or p.img_url.empty?) ? "" : p.img_url.gsub("img#{p.id}","img#{p.id}_#{Constant::P_PICSIZE[1]}")
      
      if [Product::TYPES_NAME[:CLEAN_PROD], Product::TYPES_NAME[:BEAUTIFY_PROD]].include?(p.types.to_i)
        clean_and_besuty_prod_arr << h
      elsif p.types.to_i == Product::TYPES_NAME[:DECORATE_PROD]
        decorate_prod_arr << h
      elsif p.types.to_i ==  Product::TYPES_NAME[:ASSISTANT_PROD]
        assis_prod_arr << h
      elsif p.types.to_i ==  Product::TYPES_NAME[:ELEC_PROD]
        elec_prod_arr << h
      elsif p.types.to_i ==  Product::TYPES_NAME[:OTHER_PROD]
        other_prod_arr << h
      elsif [Product::PRODUCT_END, Product::BEAUTY_SERVICE].include?(p.types.to_i)
        clean_and_beauty_service_arr << h
      elsif  p.types.to_i > Product::PRODUCT_END && p.types.to_i != Product::BEAUTY_SERVICE
        maint_service_arr << h
      end
    end

    product_arr[:清洗美容类] = clean_and_beauty_service_arr
    product_arr[:维修保养类] = maint_service_arr
    product_arr[:美容产品类] = clean_and_besuty_prod_arr
    product_arr[:装饰产品类] = decorate_prod_arr
    product_arr[:汽车配件类] = assis_prod_arr
    product_arr[:电子产品类] = elec_prod_arr
    product_arr[:汽车用品类] = other_prod_arr
    #    cards = PackageCard.find(:all,
    #      :conditions => ["status = ? and store_id = ? and
    #          ((date_types = #{PackageCard::TIME_SELCTED[:PERIOD]} and ended_at >= ?) or date_types = #{PackageCard::TIME_SELCTED[:END_TIME]})##",
    #        PackageCard::STAT[:NORMAL], store_id, Time.now])
    cards = PackageCard.find_by_sql(["select pc.*,pcmr.material_num, m.storage m_storage from
         package_cards pc left join pcard_material_relations pcmr
         on pc.id = pcmr.package_card_id left join materials m on m.id = pcmr.material_id where pc.status = ?
        and pc.store_id = ? and ((date_types = #{PackageCard::TIME_SELCTED[:PERIOD]} and ended_at >= ?)
 or date_types = #{PackageCard::TIME_SELCTED[:END_TIME]})",PackageCard::STAT[:NORMAL], store_id, Time.now])

    pcard_prod_relations = PcardProdRelation.find_by_sql(["select p.name, ppr.product_num, ppr.package_card_id
      from pcard_prod_relations ppr
      inner join products p on p.id = ppr.product_id where ppr.package_card_id in (?)", cards]).group_by{ |pcr| pcr.package_card_id }
    sv_cards = SvCard.normal_included(store_id)

    product_arr[:优惠卡类] = (cards + sv_cards || []).collect{|c|
      price = c.is_a?(SvCard) ? c.sale_price : c.price
      description = ""
      if c.is_a?(SvCard)
        description = c.description
      else
        pcard_prod_relations[c.id].each do |ppr|
          description += ppr.name + ppr.product_num.to_s + "次 \n"
        end if pcard_prod_relations[c.id]
        description += c.description.to_s
      end
      if !c.is_a?(SvCard) and c.m_storage.present? and c.material_num.present? and c.m_storage < c.material_num
        nil
      else
        h = Hash.new
        h[:id] = c.id
        h[:name] = c.name
        h[:price] = price
        h[:description] = description
        h[:img] = c.img_url
        h[:type] = c.is_a?(PackageCard) ? '2' : c.types==SvCard::FAVOR[:DISCOUNT] ? '0' : '1'
        h[:point] = c.is_a?(PackageCard) ? c.prod_point : nil
        h
      end
    }.compact
    arr[:products] = product_arr
    arr[:p_titles_order] = [:清洗美容类, :汽车用品类, :维修保养类, :美容产品类, :电子产品类, :装饰产品类, :汽车配件类, :优惠卡类]
    #    count = product_arr.values.map(&:length).max
    #    arr[:count] = count
    arr
  end

  def self.one_order_info(order_id)
    return Order.find_by_sql(["select o.*, c.name front_s_name, c3.name return_name,
      o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2, o.customer_id,o.status
      from orders o left join staffs c on c.id = o.front_staff_id  left join staffs c3 on c3.id =
      o.return_staff_id where o.id = ?", order_id]).first
  end

  #arr = [车牌和用户信息，选择的产品和服务，相关的活动，相关的打折卡，选择的套餐卡，状态，总价]
  def self.pre_order store_id,car_num,brand,car_year,user_name,phone,email,birth,prod_ids,res_time,sex,from_pcard
    arr  = []
    status = 0
    total = 0
    Customer.transaction do
      #begin
      customer = Customer.find_by_status_and_mobilephone(Customer::STATUS[:NOMAL], phone)
      customer.update_attributes(:name => user_name.strip, :mobilephone => phone,
        :other_way => email, :birthday => birth, :sex => sex) if customer
      carNum = CarNum.find_by_num car_num
      customer_infos = Customer.create_single_cus(customer, carNum, phone, car_num,
        user_name.strip, email, birth, car_year, brand.split("_")[1].to_i, sex, nil, nil, store_id)
      customer = customer_infos[0]
      carNum = customer_infos[1]
      info = Hash.new
      info[:c_id] = customer.id
      info[:car_num] = car_num
      info[:c_name] = customer.name
      info[:phone] = phone
      info[:car_brand] = (carNum.car_model and carNum.car_model.car_brand) ? carNum.car_model.car_brand.name + "-" + carNum.car_model.name : ""
      info[:car_num_id] = carNum.id
      ids = []
      #prod_ids = "10_3,311_0,226_2"
      cpcard_prod_ids = []
      if from_pcard == 1
        #prod_ids = "180_213,181_213,181_214" cpcard_realtion_id和product_id
        cpcard_prod_ids = prod_ids.split(",").collect{|pi| [pi.split("_")[0].to_i, pi.split("_")[1].to_i]}
        ids = prod_ids.split(",").map{|a| a.split("_")[1].to_i}.flatten
        pcard_ids = prod_ids.split(",").map{|a| a.split("_")[0].to_i}.flatten
      else
        prod_ids.split(",").each do |p_id|
          ids << p_id.split("_")[0].to_i if p_id.split("_")[1].to_i < 7
        end
      end
      #ids = [311, 226]
      prod_mat_relations = Product.find_by_sql(["select distinct(pmr.product_id), m.storage from prod_mat_relations pmr
      inner join materials m on m.id = pmr.material_id where m.status = #{Material::STATUS[:NORMAL]}
      and m.storage > 0 and m.store_id = ? and pmr.product_id in (?) ", store_id, ids]).group_by { |i| i.product_id } if ids.any?
      products = Product.find(:all, :conditions => ["id in (?) and is_service = #{Product::PROD_TYPES[:SERVICE]}", 
          ids]) if ids.any?
      unless products.nil? or products.blank?
        service_ids = products.collect { |p| p.id  } #[311]
        time_arr = Station.arrange_time store_id, service_ids, nil, res_time
        info[:start] = ""
        info[:end] = ""
        info[:station_id] = time_arr[0] || ""

        case time_arr[1]
        when 0
          status = 2 #没工位
        when 1
          status = 1  #有符合工位
        when 2
          status = 3 #多个工位
        when 3
          status = 4 #工位上暂无技师
        end

      else
        info[:start] = ""
        info[:end] = ""
        info[:station_id] = ""
        status = 1
      end
      arr << info
      #根据产品找活动，打折卡，套餐卡
      p_cards = []
      prod_arr = []
      sale_hash = {}
      svcard_arr = []
      prod_ids.split(",").each do |id| #["1_3_1","22_3_0","311_0","226_2"]
        if id.split("_")[1].to_i == 7
          #套餐卡
          if id.split("_")[2].to_i == 2
            has_p_card = 0
            p_c = Hash.new
            p_c = PackageCard.find_by_id_and_status_and_store_id id.split("_")[0].to_i,PackageCard::STAT[:NORMAL],store_id
            if p_c
              p_c[:products] = p_c.pcard_prod_relations.collect{|r|
                p = Hash.new
                p[:name] = r.product.name
                p[:num] = r.product_num
                p[:p_card_id] = r.package_card_id
                p[:product_id] = r.product_id
                p[:product_price] = r.product.sale_price
                p[:selected] = 1
                p
              }
            end
            p_c[:has_p_card] = has_p_card
            p_c[:show_price] = p_c[:price]
            p_cards << p_c
            total += p_c.price
          else #储值卡，打折卡
            sv_card = SvCard.find_by_id(id.split("_")[0])
            if sv_card
              show_price =  sv_card.sale_price
              s = Hash.new
              s[:scard_id] = sv_card.id
              s[:scard_name] = sv_card.name
              s[:scard_discount] = sv_card.discount
              s[:price] = show_price
              s[:selected] = sv_card.types== SvCard::FAVOR[:DISCOUNT] ? 1 : 0
              s[:show_price] = 0
              s[:card_type] = sv_card.types  #卡类型 0：打折卡， 1：储值卡
              s[:is_new] = 1  #是新买的打折或者储值卡
              svcard_arr << s
              #total -= s[:price]
              total += show_price
            end
          end
        else
          #产品
          prod = Product.find_by_store_id_and_id_and_status store_id,id.split("_")[0].to_i,Product::IS_VALIDATE[:YES]
          
          if prod
            prod_mat_num = prod_mat_relations[prod.id] ? prod_mat_relations[prod.id][0].try(:storage) : 0
            sale_hash, prod_arr, total = Order.get_sale_by_product(prod, prod_mat_num, total, sale_hash, prod_arr)
          end
        end
      end if prod_ids && carNum && customer && from_pcard!=1

      # 产品相关活动
      prod_ids.split(",").each do |pc_p|
        prod = Product.find_by_store_id_and_id_and_status store_id,pc_p.split("_")[1].to_i,Product::IS_VALIDATE[:YES]
        
        if prod
          prod_mat_num = prod_mat_relations[prod.id] ? prod_mat_relations[prod.id][0].try(:storage) : 0
          sale_hash, prod_arr, total = Order.get_sale_by_product(prod, prod_mat_num, total, sale_hash, prod_arr)
        end
      end if prod_ids && carNum && customer && from_pcard==1

      #用户相关的打折卡

      svcard_arr = customer.get_discount_cards(svcard_arr)

      #产品相关套餐卡
      if ids.any?
        if from_pcard == 1
          customer_pcards = CPcardRelation.find_by_sql(["select cpr.* from c_pcard_relations cpr
        where cpr.status = ? and cpr.ended_at >= ? and cpr.id in (?) and cpr.customer_id = ? group by cpr.id",
              CPcardRelation::STATUS[:NORMAL], Time.now, pcard_ids, customer.id])
        else
          customer_pcards = CPcardRelation.find_by_sql(["select cpr.* from c_pcard_relations cpr
        inner join pcard_prod_relations ppr on ppr.package_card_id = cpr.package_card_id
        where cpr.status = ? and cpr.ended_at >= ?  and product_id in (?) and cpr.customer_id = ? group by cpr.id",
              CPcardRelation::STATUS[:NORMAL], Time.now, ids, customer.id])
        end

        customer_pcards.each do |c_pr|
          p_c = c_pr.package_card
          p_c[:products] = p_c.pcard_prod_relations.collect{|r|
            p = Hash.new
            p[:name] = r.product.name
            prod_num = c_pr.get_prod_num r.product_id
            p[:num] = from_pcard==1 && cpcard_prod_ids.select{|cpi| cpi[0] == c_pr.id}.select{|c| c[1] == r.product_id}.present? ? prod_num.to_i - 1 : prod_num.to_i
            p[:Total_num] = prod_num.to_i if from_pcard==1
            p[:p_card_id] = r.package_card_id
            p[:product_id] = r.product_id
            p[:product_price] = r.product.sale_price
            p[:selected] = cpcard_prod_ids.select{|cpi| cpi[0] == c_pr.id}.select{|c| c[1] == r.product_id}.present? && from_pcard==1 ? 0 : 1
            p
          }
          p_c[:cpard_relation_id] = c_pr.id
          p_c[:has_p_card] = 1
          p_c[:show_price] = 0.0
          p_cards << p_c
        end if customer_pcards.any?
      end
      status = 1 if status == 0
      #prod_arr.each{|p| p[:count] = p[:count] -1 if ids.include?(p[:id])&&from_pcard==1 }
      arr << prod_arr
      arr << sale_hash.values #sale_arr
      arr << svcard_arr
      arr << p_cards
      arr << status
      arr << (from_pcard==1 ? 0 : total)
      #rescue
      #arr = [nil,[],[],[],[],status,total]
      #end
    end
    arr
  end

  def self.get_sale_by_product product, car_num_id
    sales = []
    sale_ids = SaleProdRelation.where(["product_id=?", product.id]).map(&:sale_id).uniq
    sale_ids.each do |sid|
      sale = Sale.find_by_id_and_status(sid, Sale::STATUS[:RELEASE])
      flag = 0
      if sale
        #如果该活动的时间已经过了，则忽略
        if sale.disc_time_types==Sale::DISC_TIME[:TIME] && !sale.ended_at.nil? && sale.ended_at.strftime("%Y-%m-%d") < Time.now.strftime("%Y-%m-%d")
          flag = 1
        else
          #如果该活动的参加总次数满了或者这个车牌参加的次数也满了，则也忽略
          all_len = Order.where(["status = ? and sale_id = ? and car_num_id != ?", Order::STATUS[:BEEN_PAYMENT], sale.id, car_num_id]).map(&:car_num_id).uniq.length
          everycar_len = Order.where(["status = ? and car_num_id = ? and sale_id =?", Order::STATUS[:BEEN_PAYMENT], car_num_id, sale.id]).length
          if all_len >= sale.car_num
            flag = 1
          elsif everycar_len >= sale.everycar_times
            flag = 1
          end
        end
        if flag == 0
          ha = {}
          ha[:disc_types] = sale.disc_types
          ha[:discount] = sale.disc_types == Sale::DISC_TYPES[:FEE] ? nil : sale.discount
          ha[:price] = sale.disc_types == Sale::DISC_TYPES[:FEE] ? sale.discount : nil
          ha[:sale_id] = sale.id
          ha[:sale_name] = sale.name
          ha[:selected] = 1
          ha[:show_price] = 0
          ha[:products] = []
          sale_prod_relations = SaleProdRelation.find_by_sql(["select spr.product_id, spr.prod_num, p.name
                    from sale_prod_relations spr inner join products p
                    on p.id = spr.product_id where spr.sale_id = ?", sale.id])
          sale_prod_relations.each { |spr|
            ha[:products] << {:product_id => spr.product_id, :prod_num => spr.prod_num, :name => spr.name}
          }
          sales << ha
        end
      end
    end if sale_ids
    return sales
  end
  
  #获取产品相关的活动，打折卡，套餐卡
  def self.get_prod_sale_card prods
    #"prods"=>"0_311_1,0_310_1,3_10_1_310=1-311=1-" # 打着卡：2_id_price(优惠jine)
    arr = prods.split(",")
    prod_arr = []
    sale_arr = []
    svcard_arr = []
    pcard_arr = []
    arr.each do |p|
      if p.split("_")[0].to_i == 0
        #p  0_id_count
        prod_arr << p.split("_")
      elsif p.split("_")[0].to_i == 1
        #p 1_id_prod1=price1_prod2=price2_totalprice_realy_price
        sale_arr << p.split("_")
      elsif p.split("_")[0].to_i == 2
        #p 2_id
        svcard_arr << p.split("_")
      elsif p.split("_")[0].to_i == 3
        #p 3_id_has_p_card_prodId=prodId
        pcard_arr << p.split("_")
      end
    end
    [prod_arr,sale_arr,svcard_arr,pcard_arr]
  end

  #生成订单
  def self.make_record c_id,store_id,car_num_id,start,end_at,prods,price,station_id,user_id
    #"prods"=>"0_311_1,0_310_1,3_10_1_310=1-311=1-" # 产品／服务 ：0，活动：1， 打折卡：2， 套餐卡：3
    arr = []
    status = 0
    order = nil
    send_sv_card = {}
    Order.transaction do
      #begin
      arr = self.get_prod_sale_card prods
      #2_id_card_type_（is_new）_price 储值卡格式
      #[[["0", "311", "9"], ["0", "310", "2"]], [], [[2,1,0,0,20],...], [["3", "10", "0", "310=2-311=7-"], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]]
      sale_id = arr[1].size > 0 ? arr[1][0][1] : ""  #活动
      p order_time = Product.update_order_time(arr)
      order = Order.create({
          :code => MaterialOrder.material_order_code(store_id.to_i),
          :car_num_id => car_num_id,
          :status => Order::STATUS[:NORMAL],
          :price => price,
          :is_billing => false,
          :front_staff_id => user_id,
          :customer_id => c_id,
          :store_id => store_id,
          :is_visited => IS_VISITED[:NO],
          :auto_time=>order_time[0],
          :warn_time =>order_time[1]
        })
      if order
        hash = Hash.new
        x = 0
        cost_time = 0
        prod_ids = []
        is_has_service = false #用来记录是否有服务
        order_prod_relations = [] #用来记录订单中的所有的产品+物料
        product_prices = {}
        #存储sv_cards
        if arr[2].size > 0
          used_cards = arr[2].select{|ele| ele[4].to_f > 0} || []
          used_svcard_id = used_cards.flatten[1] #已经使用的打折卡的id
          #2_id_card_type_（is_new）_price 储值卡格式
          arr[2].select{|ele| ele[3].to_i == 1}.each do |uc|
            if uc[3]=="1" #如果是新储值卡 or 打折卡
              sv_card = SvCard.find_by_id uc[1]
              if sv_card
                if sv_card.types == SvCard::FAVOR[:SAVE]  #储值卡
                  sv_prod_relation = sv_card.svcard_prod_relations[0]
                  if sv_prod_relation
                    total_price = sv_prod_relation.base_price.to_f+sv_prod_relation.more_price.to_f
                    c_sv_relation = CSvcRelation.create!( :customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => total_price,:left_price =>total_price, 
                      :status => CSvcRelation::STATUS[:invalid], :password => Digest::MD5.hexdigest(uc[5]))
                    SvcardUseRecord.create(:c_svc_relation_id =>c_sv_relation.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>total_price,
                      :left_price=>total_price,:content=>"购买#{sv_card.name}")
                    c_phone = c_sv_relation.customer.mobilephone
                    send_message = "#{sv_card.name}的余额为#{total_price}，您设置的密码为：#{uc[5]}，付款后可以使用。"
                    message_route = "/send.do?Account=#{Constant::USERNAME}&Password=#{Constant::PASSWORD}&Mobile=#{c_phone.strip}&Content=#{URI.escape(send_message)}&Exno=0"
                    send_sv_card.merge!(message_route=>Constant::MESSAGE_URL)
                  end
                else   #打折卡
                  CSvcRelation.create!(:customer_id => c_id, :sv_card_id => uc[1], :order_id => order.id, :total_price => sv_card.price, :status => CSvcRelation::STATUS[:invalid])
                end
              end
            end
          end

        end
        #创建订单的相关产品 OrdeProdRelation
        (arr[0] || []).each do |prod|
          product = Product.find_by_id_and_store_id_and_status prod[1],store_id,Product::IS_VALIDATE[:YES]
          if product
            order_p_r = OrderProdRelation.create(:order_id => order.id, :product_id => prod[1],
              :pro_num => prod[2], :price => product.sale_price, :t_price => product.t_price, :total_price => prod[3].to_f)
            order_prod_relations << order_p_r
            if product.is_service
              x += 1
              cost_time += product.cost_time.to_i * prod[2].to_i
              prod_ids << product.id
              is_has_service = true
            end
            product_prices[product.id] = product.sale_price
          end
        end
        hash[:types] = x > 0 ? TYPES[:SERVICE] : TYPES[:PRODUCT]
        if order_prod_relations  #如果是产品,则减掉对应库存
          order_prod_h = order_prod_relations.group_by { |o_p| o_p.product_id }
          materials = Material.find_by_sql(["select m.id, pmr.product_id from materials m inner join prod_mat_relations pmr
                on pmr.material_id = m.id inner join products p on p.id = pmr.product_id
                where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and pmr.product_id in (?)", order_prod_h.keys])
          materials.each do |m|
            mat = Material.find_by_id m.id
            mat.update_attributes(:storage => (mat.storage - order_prod_h[m.product_id][0].pro_num)) if mat and order_prod_h[m.product_id]
          end unless materials.blank?
        end
        #订单相关的活动
        if sale_id != "" && Sale.find_by_id_and_store_id_and_status(sale_id,store_id,Sale::STATUS[:RELEASE])
          if arr[1][0][2]
            p_prcent = arr[1][0][-1].to_f/arr[1][0][-2].to_f

            (2..(arr[1][0].length - 3)).each do |i|
              p_info = arr[1][0][i].split("=")
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE],
                :product_id => p_info[0].to_i, :price => p_info[1].to_f * p_prcent)
            end
          end
          hash[:sale_id] = sale_id
        end
        
        #订单相关的套餐卡
        prod_hash = {}  #用来记录套餐卡中总共使用了多少
        if arr[3].any?
          #[["3", "10", "0", "310=2-311=7-"], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]
          p_c_ids = {} #统计有多少套餐卡中消费
          pc_ids = {} #套餐卡同种套餐卡数量
          arr[3].collect do |a_pc|            
            pc_ids[a_pc[1].to_i] = pc_ids[a_pc[1].to_i].nil? ? 1 : (pc_ids[a_pc[1].to_i] + 1)
            pro_infos = p_c_ids[a_pc[1].to_i].nil? ? {} : p_c_ids[a_pc[1].to_i]
            pinfos = a_pc[3].split("-") if a_pc[3]
            pinfos.each do |p_f|
              id = p_f.split("=")[0].to_i
              num = p_f.split("=")[1].to_i
              pro_infos[id] = pro_infos[id].nil? ? num : (pro_infos[id].to_i + num)
              prod_hash[id] = prod_hash[id].nil? ? num : (prod_hash[id].to_i + num)
            end if pinfos and pinfos.any?
            p_c_ids[a_pc[1].to_i] = pro_infos #{10=>{310=>2, 311=>9}, 11=>{}}
          end
          #获取套餐卡
          #arr[3]=[["3", "10", "0", "310=2-311=7-", X], ["3", "11", "0"], ["3", "10", "1", "311=2-"]]
          # 3表示是套餐卡，10是套餐卡id，0表示新旧套餐卡，其后表示product或者service的id，最后是用户套餐卡关系id CPcardRelation的id
          p_cards = PackageCard.find(:all, :conditions => ["status = ? and store_id = ? and id in (?)",
              PackageCard::STAT[:NORMAL], store_id, p_c_ids.keys])
          if p_cards.any?            
            p_cards_hash = p_cards.group_by { |p_c| p_c.id }
            arr[3].collect do |a_pc|
              prod_nums = a_pc[3].split("-") if a_pc[3]
              if a_pc[2].to_i == 0 #has_p_card是0，表示是新买的套餐卡
                p_card_id = a_pc[1].to_i
                if p_cards_hash[p_card_id][0].date_types == PackageCard::TIME_SELCTED[:END_TIME]  #根据套餐卡的类型设置截止时间
                  ended_at = (Time.now + (p_cards_hash[p_card_id][0].date_month).days).to_datetime
                else
                  ended_at = p_cards_hash[p_card_id][0].ended_at
                end
                cpr = CPcardRelation.create(:customer_id => c_id, :package_card_id => p_card_id,
                  :status => CPcardRelation::STATUS[:INVALID], :ended_at => ended_at,
                  :content => CPcardRelation.set_content(p_card_id), :order_id => order.id,
                  :price => p_cards_hash[p_card_id][0].price)
                #扣掉跟套餐卡相关的物料
                pcmr = PcardMaterialRelation.find_by_package_card_id(p_card_id)
                if pcmr
                  material = pcmr.material
                  material.update_attribute(:storage, material.storage - pcmr.material_num) if material
                end

                if a_pc[3] # 如果使用套餐卡，把使用的次数保存
                  (prod_nums||[]).each do |pn|
                    prod_id = pn.split("=")[0]
                    p_num = pn.split("=")[1]
                    OPcardRelation.create({:order_id => order.id, :c_pcard_relation_id => cpr.id,
                        :product_id =>prod_id, :product_num => p_num}) if cpr
                  end
                end
              else #已经买过套餐卡
                ## 如果使用套餐卡，把使用的次数保存
                cpr = CPcardRelation.find_by_id a_pc[4]
                (prod_nums||[]).each do |pn|
                  prod_id = pn.split("=")[0]
                  p_num = pn.split("=")[1]
                  OPcardRelation.create({:order_id => order.id, :c_pcard_relation_id => a_pc[4],
                      :product_id =>prod_id, :product_num => p_num}) if cpr
                end
              end
              if cpr
                prod_nums_hash = {}
                (prod_nums||[]).map{|pn| pn.split("=")}.map{|pn| prod_nums_hash[pn[0]] = pn[1]}
                cpr_content = cpr.content.split(",") 
                content = []
                (cpr_content ||[]).each do |pnn|
                  prod_name_num = pnn.split("-")
                  prod_id = prod_name_num[0]
                  if prod_nums_hash[prod_id]
                    content << "#{prod_id.to_i}-#{prod_name_num[1]}-#{prod_name_num[2].to_i - prod_nums_hash[prod_id].to_i}"
                  else
                    content << pnn
                  end
                end
                cpr.update_attribute(:content, content.join(","))
              end
            end            
            #创建套餐卡优惠的价格
            unless prod_hash.empty?
              prod_hash.each { |k, v|
                pcard_dis_price = product_prices[k].to_f * v
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
                  :product_id => k, :price => pcard_dis_price, :product_num => v)
              }
            end
          end
        end

        #订单相关的打折卡(使用的)
        unless used_svcard_id.blank?
          sv_card = SvCard.find_by_id(used_svcard_id)
          if sv_card
            c_sv_relation = CSvcRelation.find_by_customer_id_and_sv_card_id c_id,used_svcard_id
            c_sv_relation = CSvcRelation.create(:customer_id => c_id, :sv_card_id => used_svcard_id) if c_sv_relation.nil?
            order_prod_relations.each do |o_p_r|
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :product_id => o_p_r.product_id, :price => (o_p_r.total_price.to_f) *((10 - sv_card.discount).to_f/10))
            end if arr[2][0][2] and order_prod_relations.any?
            csvc_relations = CSvcRelation.where(:order_id => order.id)
            csvc_relations.each do |csvc_relation|
              sv_card_new = SvCard.find_by_id(csvc_relation.sv_card_id)
              sv_price =  sv_card_new.sale_price
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :price => (sv_price.to_f) *((10 - sv_card.discount).to_f/10))
            end
            c_pcard_relations = CPcardRelation.where(:order_id => order.id)
            c_pcard_relations.each do |cpr|
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                :price => (cpr.price.to_f) *((10 - sv_card.discount).to_f/10))
            end
            hash[:c_svc_relation_id] = c_sv_relation.id if c_sv_relation
          end
        end

        if is_has_service
          #创建工位订单
          arrange_time = Station.arrange_time(store_id,prod_ids,order)
          if arrange_time[0]
            new_station_id = arrange_time[0]  #获取所有支持所需的服务的工位
          end

          #下单排工位
          hash = Station.create_work_order(new_station_id, store_id,order, hash, arrange_time[2],cost_time)
          if order.update_attributes hash
            status = 1
          end
 
        else
          hash[:station_id] = ""
          hash[:cons_staff_id_1] = ""
          hash[:cons_staff_id_2] = ""
          hash[:started_at] = start
          hash[:ended_at] = end_at
          hash[:status] = STATUS[:WAIT_PAYMENT]
          order.update_attributes hash
          status = 1
        end
       
      end
      #rescue
      #status = 2
      #end
    end
    arr[0] = status
    arr[1] = order
    arr[2] = send_sv_card
    arr
  end

  #返回订单的相关信息
  def get_info
    hash = Hash.new
    hash[:id] = self.id
    hash[:code] = self.code
    car_num = self.car_num
    hash[:car_num] = car_num.num
    hash[:username] = self.customer.name
    hash[:userid] = self.customer.id
    hash[:start] = self.started_at.strftime("%Y-%m-%d %H:%M") if self.started_at
    hash[:end] = self.ended_at.strftime("%Y-%m-%d %H:%M") if self.ended_at
    hash[:total] = self.price
    content = ""
    realy_price = 0
    sale = nil
    unless self.sale_id.blank?
      h = {}
      sale = self.sale
      h[:name] = sale.name
      self.order_pay_types.each do |o_p_t|
        if o_p_t.pay_type == OrderPayType::PAY_TYPES[:SALE]
          h[:price] = h[:price].nil? ? o_p_t.price.to_f : (h[:price] + o_p_t.price.to_f)
        end
      end
      h[:type] = 1
      hash[:sale] = h
    end

    hash[:products] = self.order_prod_relations.collect{|r|
      h = Hash.new
      h[:id] = r.product_id
      h[:name] = r.product.name
      h[:price] = r.price
      h[:num] = r.pro_num.to_i
      h[:type] = 0
      content += h[:name] + ","
      h
    }
    hash[:content] = content.chomp(",")

    #订单确认后显示页面上面关于打折卡信息
    hash[:c_svc_relation] = []
    csvc_relations = CSvcRelation.where(:order_id => self.id).each{|csvc| csvc[:is_new] = 1}
    unless self.c_svc_relation_id.blank?
      csvc_relation = CSvcRelation.find_by_id(self.c_svc_relation_id)
      csvc_relation[:is_new] = 0 if csvc_relation
      csvc_relations << csvc_relation
    end

    sav_price = 0
    self.order_pay_types.each do |o_p_t|
      if o_p_t.pay_type == OrderPayType::PAY_TYPES[:DISCOUNT_CARD]
        sav_price += o_p_t.price
      end
    end
    csvc_relations.each do |csvc|
      h = {}
      sv_card = SvCard.find_by_id(csvc.sv_card_id)
      price =  sv_card.sale_price
      h[:name] = sv_card.name
      h[:price] = ((csvc.id == self.c_svc_relation_id) ? sav_price : price)
      h[:discount] = sv_card.types==SvCard::FAVOR[:DISCOUNT] ? sv_card.discount : 0  #0表示是储值卡
      h[:type] = 2
      h[:card_type] = sv_card.types #0 打折卡 1 储值卡
      h[:is_new] = csvc.is_new
      hash[:c_svc_relation] << h
    end unless csvc_relations.blank?
    hash[:c_pcard_relation] = []
    customer_pcards = CPcardRelation.find_by_sql(["select pc.* from c_pcard_relations cpr
        inner join package_cards pc on pc.id = cpr.package_card_id
        where cpr.order_id = ?", self.id])
    customer_pcards.each do |cp|
      hash[:c_pcard_relation] << {:name => cp.name, :price => cp.price, :num => 1, :type => 3}
      content += cp.name + ","
      realy_price += cp.price
    end unless customer_pcards.blank?
    self.o_pcard_relations.group_by{|opr| opr.c_pcard_relation_id}.each do |c_pcard_relarion_id, oprs|
      cpr = CPcardRelation.find_by_id c_pcard_relarion_id
      name = cpr.package_card.name
      price = oprs.map{|opr| [opr.product.sale_price.to_f, opr.product_num]}.inject(0){|sum, pn| sum += pn[0].to_f*pn[1].to_f}.to_f
      hash[:c_pcard_relation] << {:name => name, :price => -price, :num => 1, :type => 3}
    end
    hash
  end

  #支付订单根据选择的支付方式
  def self.pay order_id, store_id, please, pay_type, billing, code, is_free, qfpos_id
    order = Order.find_by_id_and_store_id order_id,store_id
    status = 0
    if order
      Order.transaction do
        begin
          hash = Hash.new
          hash[:is_billing] = billing.to_i == 0 ? false : true
          hash[:is_pleased] = please.to_i
          hash[:qfpos_id] = qfpos_id
          hash[:is_vip] = Customer::IS_VIP[:NORMAL]
          if is_free.to_i == 0
            hash[:status] = STATUS[:BEEN_PAYMENT]
            hash[:is_free] = false
          else
            hash[:status] = STATUS[:FINISHED]
            hash[:is_free] = true
            hash[:price] = 0
          end
          #如果有套餐卡，则更新状态
          c_pcard_relations = CPcardRelation.find_all_by_order_id(order.id)
          c_pcard_relations.each do |cpr|
            cpr.update_attribute(:status, CPcardRelation::STATUS[:NORMAL])
          end unless c_pcard_relations.blank?
          #如果有买储值卡，则更新状态
          csvc_relations = CSvcRelation.where(:order_id => order.id)
          csvc_relations.each{|csvc_relation| csvc_relation.update_attributes({:status => CSvcRelation::STATUS[:valid], :is_billing => hash[:is_billing]})}
          if c_pcard_relations.present? || csvc_relations.present?
            hash[:is_vip] = Customer::IS_VIP[:VIP]
          end
          #如果是选择储值卡支付
          if pay_type.to_i == OrderPayType::PAY_TYPES[:SV_CARD] && code
            #c_svc_relation = CSvcRelation.find_by_id order.c_svc_relation_id
            #if c_svc_relation && c_svc_relation.left_price.to_f >= order.price.to_f
            content = "订单号为：#{order.code},消费：#{order.price}."
            #sv_use_record = SvcardUseRecord.create(:c_svc_relation_id => c_svc_relation.id,
            #                                       :types => SvcardUseRecord::TYPES[:OUT],
            #                                       :use_price => order.price,
            #                                       :content => content,
            #                                       :left_price => (c_svc_relation.left_price - order.price)
            #)
            #c_svc_relation.update_attribute(:left_price,sv_use_record.left_price) if sv_use_record
            svc_return_record = SvcReturnRecord.find_all_by_store_id(store_id,:order => "created_at desc", :limit => 1)
            if svc_return_record.size > 0
              total = svc_return_record[0].total_price - order.price
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => total)
            else
              SvcReturnRecord.create(:store_id => store_id, :price => order.price, :types => SvcReturnRecord::TYPES[:OUT],
                :content => content, :target_id => order.id, :total_price => -order.price)
            end
            
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
          else
            OrderPayType.create(:order_id => order_id, :pay_type => pay_type.to_i, :price => order.price)
            status = 1
          end
          wo = WorkOrder.find_by_order_id(order.id)
          wo.update_attribute(:status, WorkOrder::STAT[:COMPLETE]) if wo and wo.status==WorkOrder::STAT[:WAIT_PAY]
          #生成积分的记录
          c_customer = order.customer
          if c_customer && c_customer.is_vip
            points = Order.joins(:order_prod_relations=>:product).select("products.prod_point*order_prod_relations.pro_num point").
              where("orders.id=#{order.id}").inject(0){|sum,porder|(porder.point.nil? ? 0 :porder.point)+sum}+
              PackageCard.find(c_pcard_relations.map(&:package_card_id)).map(&:prod_point).compact.inject(0){|sum,pcard|sum+pcard}
            Point.create(:customer_id=>c_customer.customer_id,:target_id=>order.id,:target_content=>"购买产品/服务/套餐卡获得积分",:point_num=>points,:types=>Point::TYPES[:INCOME])
            c_customer.update_attributes(:total_point=>points+(c_customer.total_point.nil? ? 0 : c_customer.total_point))
          end
          #生成出库记录
          order_mat_infos = Order.find_by_sql(["SELECT o.id o_id, o.front_staff_id, p.id p_id, opr.pro_num material_num, m.id m_id,
          m.price m_price,m.detailed_list FROM orders o inner join order_prod_relations opr on o.id = opr.order_id inner join products p on
          p.id = opr.product_id inner join prod_mat_relations pmr on pmr.product_id = p.id inner join materials m
           on m.id = pmr.material_id where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and o.status in (?) and o.id = ?", [STATUS[:BEEN_PAYMENT], STATUS[:FINISHED]], order.id])
          order_mat_infos.each do |omi|
            MatOutOrder.create({:material_id => omi.m_id, :staff_id => omi.front_staff_id, :material_num => omi.material_num,
                :price => omi.m_price, :types => MatOutOrder::TYPES_VALUE[:sale], :store_id => store_id,:detailed_list=>omi.detailed_list})
          end
          #更新订单提成
          hash[:front_deduct],hash[:technician_deduct] = 0,0
          hash[:front_deduct] += PackageCard.select("ifnull(sum(deduct_price+deduct_percent),0) sum").where(:id=>c_pcard_relations.map(&:package_card_id)).first.sum unless c_pcard_relations.blank?
          deduct_order = Order.joins(:order_prod_relations=>:product).select("ifnull(sum((deduct_price+deduct_percent)*pro_num),0) deduct_sum,
          ifnull(sum((techin_price+techin_percent)*pro_num),0) technician_sum").where("orders.id=#{order.id}").first
          hash[:front_deduct] += deduct_order.deduct_sum
          hash[:technician_deduct] += deduct_order.technician_sum/2.0
          order.update_attributes hash
          
        rescue => error
          p error
          status = 2
        end
      end
    else
      status = 2
    end
    [status]
  end

  def self.checkin store_id,car_num,brand,car_year,user_name,phone,email,birth,sex
    car_num_r = CarNum.find_by_num car_num
    customer = Customer.find_by_status_and_mobilephone(Customer::STATUS[:NOMAL], phone)
    status = 0
    begin
      if car_num
        Customer.transaction do
          customer.update_attributes(:name => user_name.strip, :mobilephone => phone,
            :other_way => email, :birthday => birth, :sex => sex) if customer
          Customer.create_single_cus(customer, car_num_r, phone, car_num,
            user_name.strip, email, birth, car_year, brand.split("_")[1].to_i, sex, nil, nil, store_id)
        end
        status = 1
      end
    rescue
      status = 2
    end
    status
  end

  def calculate_gross_profit
    #使用过套餐卡计算毛利
    used_pcards_gross_profit = 0
    self.o_pcard_relations.each do |opr|
      oprod_r = self.order_prod_relations.where(:product_id => opr.product_id).first
      total_price = oprod_r.total_price.to_f  #每项商品总价
      deals_price = (opr.product_num * oprod_r.price).to_f #每项商品使用套餐卡抵付的价格
      prod_full_price_num = oprod_r.pro_num - opr.product_num #未使用套餐卡抵付的商品数目
      gross_profit = total_price - deals_price - prod_full_price_num *(oprod_r.t_price.to_f) #一个商品使用套餐卡后的毛利
      used_pcards_gross_profit += gross_profit
    end
    
    ###### 计算order中的总零售价

    # 商品跟服务的总零售价
    sum_products_price = self.order_prod_relations.inject(0){|sum,opr| sum += opr.total_price.to_f}
    # 购买套餐卡总价格
    sum_pcard_price = self.c_pcard_relations.inject(0){|sum,cpr| sum += cpr.price.to_f}

    #### 商品跟套餐卡购买总零售价
    total_sale_price = sum_products_price + sum_pcard_price

    # 使用活动优惠总价
    sum_sale_price = self.order_pay_types.where(:pay_type => OrderPayType::PAY_TYPES[:SALE]).inject(0){|sum,opr| sum += opr.price.to_f}
    # 使用打折卡优惠总价
    sum_savcard_price = self.order_pay_types.where(:pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD]).inject(0){|sum,opr| sum += opr.price.to_f}

    ######  计算总成本价

    #order中的商品跟服务的总成本价
    products_sum_cost_price = self.order_prod_relations.inject(0){|sum,opr| sum+=(opr.t_price.to_f)*opr.pro_num}
    #购买套餐卡总成本
    pcards_sum_cost_price = self.c_pcard_relations.map{|cpr| cpr.package_card}.compact.map{|pc| pc.pcard_prod_relations.map{|ppr| ppr.product}.inject(0){|sum,opr| sum += opr.t_price.to_f}}.inject(0){|sum,pc| sum += pc}

    ##### 商品跟套餐卡购买总成本价
    total_cost_price = products_sum_cost_price + pcards_sum_cost_price

    total_gross_price = total_sale_price - sum_sale_price - sum_savcard_price - total_cost_price + used_pcards_gross_profit
    return [total_cost_price.to_f, total_sale_price.to_f, total_gross_price.to_f > 0 ? total_gross_price.to_f : 0]
  end


  def return_order_materials # 取消订单后，退回产品或者服务相关物料数量
    order_products = self.order_prod_relations.group_by { |opr| opr.product_id }
    unless order_products.empty?  #如果是产品,则减掉要加回来
      materials = Material.find_by_sql(["select m.id, pmr.product_id from materials m inner join prod_mat_relations pmr
                on pmr.material_id = m.id inner join products p on p.id = pmr.product_id
                where p.is_service = #{Product::PROD_TYPES[:PRODUCT]} and pmr.product_id in (?)", order_products.keys])
      materials.each do |m|
        mat = Material.find_by_id m.id
        mat.update_attributes(:storage => (mat.storage + order_products[m.product_id][0].pro_num)) if mat and order_products[m.product_id]
      end unless materials.blank?
    end
    #归还跟套餐卡相关的物料
    cpcard_relations = self.c_pcard_relations
    if cpcard_relations.present?
      package_card_ids = cpcard_relations.map(&:package_card_id)
      pcmrs = PcardMaterialRelation.where(:package_card_id => package_card_ids)
      pcmrs.each do |pcmr|
        material = pcmr.material
        material.update_attribute(:storage, material.storage + pcmr.material_num) if material
      end if pcmrs.present?
    end
  end

  def return_order_pacard_num # 取消订单后，退回使用套餐卡数量
    oprs = OPcardRelation.find_all_by_order_id(self.id)
    oprs.each do |opr|
      cpr = CPcardRelation.find_by_id(opr.c_pcard_relation_id)
      pns = cpr.content.split(",").map{|pn| pn.split("-")} if cpr
      pns.each do |pn|
        pn[2] = pn[2].to_i + opr.product_num if pn[0].to_i == opr.product_id
      end if pns
      cpr.update_attribute({:content=>pns.map{|pn| pn.join("-")}.join(","),:status=>CPcardRelation::STATUS[:NORMAL]}) if cpr
    end unless oprs.blank?
  end

  def rearrange_station  #如果存在work_order,取消订单后设置work_order以及wk_or_times里面的部分数值
    work_order = self.work_orders[0]
    
    unless work_order.blank?
      if work_order.status == WorkOrder::STAT[:SERVICING]
        work_order.update_attribute(:status, WorkOrder::STAT[:CANCELED])
        work_order.arrange_station
      else
        work_order.update_attribute(:status, WorkOrder::STAT[:CANCELED])
      end
    end
  end
  
end
