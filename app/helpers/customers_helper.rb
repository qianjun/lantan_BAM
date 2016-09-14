#encoding: utf-8
module CustomersHelper

  SEL_METHODS = {:PCARD => 2,:SV =>1,:DIS =>0 ,:BY_PCARD => 3, :BY_SV => 4,:PROD =>6,:SERV =>5}
  #1 购买储值卡 0  购买打折卡 2 购买套餐卡 3 通过套餐卡购买 4 通过打折卡购买 5 购买服务 6 购买产品
  SEL_PROD = [SEL_METHODS[:BY_PCARD],SEL_METHODS[:BY_SV],SEL_METHODS[:PROD],SEL_METHODS[:SERV]]
  SEL_SV = [SEL_METHODS[:SV],SEL_METHODS[:DIS]]
  def get_cus_car_num customer_id   #获取某个客户的所有车牌及车型
    nums = CarNum.find_by_sql(["select cn.num,cm.name mname,cb.name bname from customer_num_relations cnr
        inner join car_nums cn on cnr.car_num_id=cn.id
        left join car_models cm on cn.car_model_id=cm.id
        left join car_brands cb on cm.car_brand_id=cb.id
        where cnr.customer_id=?", customer_id])
    num_str = nums.inject([]){|a,n| a << n.num;a} if nums.any?
    brand_str = nums.inject([]){|a,n| a << "#{n.bname} #{n.mname}";a} if nums.any?
    return [num_str.nil? ? "" : num_str.uniq.join(","), brand_str.nil? ? "" : brand_str.uniq.join(",")]
  end

  def create_item(total_info,ids,customer,car_num,user_id,store_id)
    order_parm = {:car_num_id => car_num.id,:is_billing => false,:front_staff_id =>user_id,
      :customer_id=>customer.id,:store_id=>store_id,:is_visited => Order::IS_VISITED[:NO]
    }
    m_msg = ""
    sv_cards,c_svc_relation,msg,order_pay_type,message_arr,redirect ={},[],[],[],[],true
    if ids[1]
      sv_cards = SvCard.where(:store_id=>store_id,:id=>ids[1]).inject({}){|h,s|h[s.id]=s;h}
      sv_price = SvcardProdRelation.where(:sv_card_id=>ids[1]).select("ifnull(sum(base_price+more_price),0) price,sv_card_id s_id").group("s_id").inject({}){|h,p|h[p.s_id]=p.price;h}
    end

    if  total_info[SEL_METHODS[:SV]]
      send_message = "您好，您购买的储值卡"
      total_info[SEL_METHODS[:SV]].each do |sv,num|
        s = sv.split("_")
        order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:SAVE],
              :price=>sv_cards[s[2].to_i].price,:status => Order::STATUS[:WAIT_PAYMENT]}))
        c_svc_relation <<  CSvcRelation.new(:customer_id =>customer.id,:sv_card_id =>s[2].to_i, :order_id => order.id,
          :status => CSvcRelation::STATUS[:invalid],:total_price =>sv_price[s[2].to_i],  :left_price =>sv_price[s[2].to_i],
          :id_card=>add_string(8,CSvcRelation.joins(:customer).where(:"customers.store_id"=>store_id).count),:password=>Digest::MD5.hexdigest("#{customer.mobilephone[-6..-1]}"))
        message_arr << "#{sv_cards[s[2].to_i].name},余额为#{sv_price[s[2].to_i]}元"
      end
      send_message += message_arr.join("、")+"，密码是#{customer.mobilephone[-6..-1]}，请您尽快付款使用。"
      m_msg = message_data(store_id,send_message,customer,car_num.id,MessageRecord::M_TYPES[:BUY_SV])
    end
    
    if total_info[SEL_METHODS[:DIS]]
      total_info[SEL_METHODS[:DIS]].each do |dis,num|
        d = dis.split("_")
        order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:DISCOUNT],
              :price=>sv_cards[d[2].to_i].price,:status => Order::STATUS[:WAIT_PAYMENT]}))
        c_svc_relation <<  CSvcRelation.new(:customer_id=>customer.id,:sv_card_id =>d[2].to_i, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
      end
    end

    if  total_info[SEL_METHODS[:PCARD]]
      pcard = PackageCard.where(:store_id=>store_id,:id=>ids[2]).inject({}){|h,s|h[s.id]=s;h}
      card_content = PcardProdRelation.find_by_sql("select package_card_id p_id,group_concat(p.id,'-',p.name,'-',ppr.product_num) content from
         pcard_prod_relations ppr  inner join products p on ppr.product_id=p.id where ppr.package_card_id in (#{pcard.keys.join(',')})
         group by package_card_id").inject({}){|h,p|h[p.p_id]=p.content;h}
      #这个库存判断 因为是一个物料
      pmrs = PcardMaterialRelation.joins(:material).select("package_card_id p_id,material_id m_id,storage-material_num result").
        where(:package_card_id =>pcard.keys).group("package_card_id").inject({}){|h,p|h[p.p_id]=[p.result,p.m_id];h}
      send_message = "#{customer.name}：您好，您购买的套餐卡:"
      total_info[SEL_METHODS[:PCARD]].each do |p_card,num|
        c = p_card.split("_")
        card = pcard[c[2].to_i]
        #如果套餐卡未绑定物料 或者 剩余库存大于0 且有内容的才可以购买
        if pmrs[card.id].nil? || ((pmrs[card.id] && pmrs[card.id][0] >= 0) && card_content[card.id])
          time = card.is_auto_revist ? Time.now + card.auto_time.to_i.hours : nil
          order = Order.create(order_parm.merge({:code => MaterialOrder.material_order_code(store_id),:types => Order::TYPES[:SAVE],:auto_time =>time ,:status => Order::STATUS[:WAIT_PAYMENT],
                :warn_time => card.auto_warn ? Time.now + card.time_warn.to_i.days : nil,:price=>card.price}))
          ended_at = card.date_types == PackageCard::TIME_SELCTED[:PERIOD] ? card.ended_at : Time.now + card.date_month.to_i.days
          c_pcard = CPcardRelation.create(:customer_id =>customer.id,:package_card_id => card.id, :ended_at => ended_at.strftime("%Y-%m-%d")+" 23:59:59",:price => card.price,
            :status => CPcardRelation::STATUS[:INVALID], :content => card_content[card.id], :order_id => order.id)
          send_message += "#{card.name}："
          c_pcard.content.split(",").each do |single_card|
            name = single_card.split('-')[1].force_encoding("ASCII-8BIT").force_encoding("UTF-8")
            send_message += "#{name}#{single_card.split('-')[2]}次，"
          end
          send_message += "有效期截至#{ended_at.strftime("%Y-%m-%d")}。"
          Material.update_storage(pmrs[card.id][1],pmrs[card.id][0],user_id,"购买套餐卡扣掉库存",nil,order)  if pmrs[card.id] #更新库存并生成出库记录
        else
          msg << "#{card.name} 库存不足！"
          redirect = false
        end
      end
      send_message += "请付款使用。"
      m_msg = message_data(store_id,send_message,customer,car_num.id,MessageRecord::M_TYPES[:BUY_PCARD])
    end

    if  total_info[SEL_METHODS[:BY_PCARD]]
      send_message = "#{customer.name}：您好，您的套餐卡"
      send = false
      total_info[SEL_METHODS[:BY_PCARD]].each do |prod,num|
        p = prod.split("_")
        result = OrderProdRelation.make_record(p[2].to_i,num.to_i,user_id,customer.id,car_num.id,store_id)
        unless result[1] == ""
          msg <<  result[1]
          redirect = false
        end
        if result[0] == 1
          send = true
          cpr = CPcardRelation.where(:id=>p[0],:status =>CPcardRelation::STATUS[:NORMAL],:customer_id=>customer.id).first
          cpr_content,acontent,yes = cpr.content.split(","),[],true #[2-产品1-22,56-服务2-3, 17-产品2-3]
          (cpr_content ||[]).each do |cc|
            ccid = cc.split("-")[0].to_i
            ccname = cc.split("-")[1]
            cccount = cc.split("-")[2].to_i
            if num && ccid == p[2].to_i
              acontent << "#{ccid}-#{ccname}-#{cccount - num}"
              yes = false if cccount > num
            else
              acontent << "#{ccid}-#{ccname}-#{cccount}"
              yes = false if cccount >0
            end
          end
          deduct = (result[2].deduct_price.nil? ? 0 : result[2].deduct_price) +(result[2].deduct_percent.nil? ? 0 : result[2].deduct_percent)
          t_deduct = result[2].techin_price+result[2].techin_percent
          update_status = {:content=>acontent.join(",")}
          update_status.merge(:status=>CPcardRelation::STATUS[:NOTIME]) if yes
          cpr.update_attributes(update_status)
          msg <<  result[1] unless result[1] == ""
          result[3].update_attributes(:status=>Order::STATUS[:BEEN_PAYMENT],:front_deduct=>deduct,:technician_deduct=>t_deduct, :c_pcard_relation_id => cpr.id)
          tech_orders =  result[3].tech_orders
          tech_orders.update_all(:own_deduct =>t_deduct/tech_orders.length ) unless tech_orders.blank?
          OPcardRelation.create(:order_id => result[3].id, :c_pcard_relation_id => cpr.id, :product_id => p[2].to_i, :product_num => num)
          package_card = PackageCard.find(cpr.package_card_id)
          product = Product.find p[2].to_i
          send_message += "#{package_card.name}已使用#{result[2].name}#{num}次，"
          if yes
            send_message += "已经使用完."
          else
            send_message += "剩余项目为："
            acontent.each do |single_card|
              send_message += "#{single_card.split('-')[1]}#{single_card.split('-')[2]}次，"
            end
            send_message += "有效期截至#{cpr.ended_at.strftime("%Y-%m-%d")}."
          end
          if  package_card && package_card.sale_percent && product.sale_price #如果数据有误  将不生成优惠金额 只生成套餐卡付款方式
            pay_price = product.sale_price * num * package_card.sale_percent.round(2)
            sale_price= (product.sale_price * num) - pay_price
            order_pay_type << OrderPayType.new(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:FAVOUR], :price => sale_price.to_f,
              :product_id => p[2].to_i, :product_num => num)
          end
          order_pay_type << OrderPayType.new(:order_id =>result[3].id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD], :price => pay_price.nil? ? 0 : pay_price.to_f,
            :product_id => p[2].to_i, :product_num => num)
        end
      end
      m_msg = message_data(store_id,send_message,customer,car_num.id,MessageRecord::M_TYPES[:USE_PCARD]) if send
    end

    if  total_info[SEL_METHODS[:BY_SV]]
      total_info[SEL_METHODS[:BY_SV]].each do |sv,num|
        v = sv.split("_")
        discount = SvcardProdRelation.where(:product_id =>v[2].to_i,:sv_card_id =>v[0].to_i).first.product_discount
        result = OrderProdRelation.make_record(v[2].to_i,num.to_i,user_id,customer.id,car_num.id,store_id)
        if result[3]
          order_pay_type <<  OrderPayType.new(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
            :price =>result[2].sale_price*num.to_i*(100-discount)/100.0, :product_id =>v[2].to_i, :product_num =>num)
        end
        unless result[1] == ""
          msg <<  result[1]
          redirect = false
        end
      end
    end
    msg << m_msg if m_msg != ""
    info = [msg,redirect]
    info = prod_serv(total_info[SEL_METHODS[:PROD]],user_id,customer.id,car_num.id,store_id,info)
    info = prod_serv(total_info[SEL_METHODS[:SERV]],user_id,customer.id,car_num.id,store_id,info)
    OrderPayType.import order_pay_type unless order_pay_type.blank?
    CSvcRelation.import  c_svc_relation unless c_svc_relation.blank?
    info
  end

  def prod_serv(items,user_id,customer_id,car_num_id,store_id,info)
    if items
      items.each do |item,num|
        p = item.split("_")
        result = OrderProdRelation.make_record(p[2].to_i,num.to_i,user_id,customer_id,car_num_id,store_id)
        unless result[1] == ""
          info[0] <<  result[1]
          info[1] = false
        end
        if result[3] && result[2]
          sales = Sale.joins(:sale_prod_relations).where(:"sales.store_id"=>store_id,:"sale_prod_relations.product_id"=>result[2].id).
            where("sale_prod_relations.prod_num <= #{num} and sales.status =#{Sale::STATUS[:RELEASE]}").select("sales.*,sale_prod_relations.prod_num")
          unless sales.blank?
            suit_sale = {}
            sales.each do |sale|
              flag = 0
              if sale.disc_time_types==Sale::DISC_TIME[:TIME] && !sale.ended_at.nil? &&
                  sale.ended_at.strftime("%Y-%m-%d") < Time.now.strftime("%Y-%m-%d") #如果该活动的时间已经过了，则忽略
                flag = 1
              else
                sql = "car_num_id != #{car_num_id}"
                sql1 = "car_num_id = #{car_num_id}"
                if sale.disc_time_types == Sale::DISC_TIME[:DAY]
                  sql += " and date_format(created_at,'%Y-%m-%d')=#{Time.now.strftime('%Y-%m-%d')}"
                  sql1 += " and date_format(created_at,'%Y-%m-%d')=#{Time.now.strftime('%Y-%m-%d')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:MONTH]
                  sql += " and date_format(created_at,'%Y-%m')=#{Time.now.strftime('%Y-%m')}"
                  sql1 += " and date_format(created_at,'%Y-%m')=#{Time.now.strftime('%Y-%m')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:YEAR]
                  sql += " and date_format(created_at,'%Y')=#{Time.now.strftime('%Y')}"
                  sql1 += " and date_format(created_at,'%Y')=#{Time.now.strftime('%Y')}"
                elsif sale.disc_time_types == Sale::DISC_TIME[:WEEK]
                  sql += "  and YEARWEEK(date_format(created_at,'%Y-%m-%d')) = YEARWEEK(now())"
                  sql1 += " and YEARWEEK(date_format(created_at,'%Y-%m-%d')) = YEARWEEK(now())"
                end
                #活动关联的车辆信息
                order_sales = Order.where(:status=>Order::STATUS[:BEEN_PAYMENT],:sale_id=>sale.id).where(sql).group("car_num_id").length
                #当前车辆关联的活动信息
                car_sales  = Order.where(:status=>Order::STATUS[:BEEN_PAYMENT],:sale_id=>sale.id).where(sql1).count[0]
                if order_sales >= sale.car_num
                  flag = 1
                elsif car_sales >= sale.everycar_times
                  flag = 1
                end
              end
              if flag == 0
                if sale.disc_types == Sale::DISC_TYPES[:FEE]
                  suit_sale[sale.discount] = sale.id
                else
                  suit_sale[((10-sale.discount)*result[2].sale_price*num.to_i/10).round(2)] = sale.id
                end
              end
            end
            sale_price = suit_sale.sort[-1]
            if sale_price
              OrderPayType.create(:order_id => result[3].id, :pay_type => OrderPayType::PAY_TYPES[:SALE],
                :price =>sale_price[0], :product_id =>result[2], :product_num =>num)
              result[3].update_attribute(:sale_id,sale_price[1])
              info[0] << "#{result[2].name}已匹配活动: #{Sale.find(sale_price[1]).name}"
            end
          end
        end
      end
    end
    info
  end

  #保留金额的两位小数
  def limit_float(num)
    return ((num.to_f*100).to_i/100.0).round(2)
  end

  def deal_order(param)
    customer = Customer.where(:store_id=>param[:store_id],:id=>param[:customer_id]).first
    order_pay_types,orders,is_vip,may_pay = [],[],false,true
    card_price,msg,is_billing = {},"付款成功！",param[:pay_order][:is_billing].to_i
    store = Store.find param[:store_id]
    if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
      if store.limited_password.nil?  or store.limited_password != Digest::MD5.hexdigest(param[:pay_cash])
        may_pay,msg = false,"免单密码有误！"
      end
    elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]
      if customer.allowed_debts == Customer::ALLOWED_DEBTS[:NO]
        may_pay,msg = false,"该客户不允许挂账！"
      else
        pay_type = OrderPayType.joins(:order=>:customer).select("ifnull(sum(order_pay_types.price),0) total_price,
        ifnull(min(date_format(order_pay_types.created_at,'%Y-%m-%d')),date_format(now(),'%Y-%m-%d')) min_time").where(
          :pay_type=>OrderPayType::PAY_TYPES[:HANG],:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE],
          :"orders.customer_id"=>param[:customer_id],:"orders.store_id"=>param[:store_id]).first
        time = customer.check_type == Customer::CHECK_TYPE[:MONTH] ? pay_type.min_time.to_date+customer.check_time.months : pay_type.min_time.to_date+customer.check_time.weeks
        if Time.now > time
          may_pay,msg = false,"上一个周期未付款，不能挂账！"
        elsif customer.debts_money < limit_float(param[:pay_cash].to_f + pay_type.total_price.to_f)
          may_pay,msg = false,"挂账额度余额为#{(customer.debts_money-pay_type.total_price.to_f).round(2)}！"
        end
      end
    end
    if may_pay && param[:pay_order] && param[:pay_order][:text]   #验证密码
      CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
        if c_relation.password != Digest::MD5.hexdigest(param[:pay_order][:"#{c_relation.id}"]) || c_relation.left_price < param[:pay_order][:text][:"#{c_relation.id}"].to_f
          may_pay,msg = false,"储值卡密码错误！"
        end
        use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_f
        card_price[c_relation.sv_card_id].nil? ?  card_price[c_relation.sv_card_id]=use_price : card_price[c_relation.sv_card_id] += use_price
      end
    end
    if may_pay   #如果密码正确
      OrderPayType.transaction do
        sql = '1=1'
        if param[:pay_order] && param[:pay_order][:return_ids]  #如果有退单
          sql += " and id not in (#{param[:pay_order][:return_ids].join(',')})"
          return_orders = Order.where(:id=>param[:pay_order][:return_ids])
          return_orders.update_all(:status=>Order::STATUS[:RETURN],:return_types=>Order::IS_RETURN[:YES])
          return_orders.each do|order|
            order.return_order_pacard_num  #如果是套餐卡退回使用次数
            order.return_order_materials  #退回产品或者服务相关物料数量
            order.rearrange_station
          end
        end
        orders = Order.where(:status=>Order::CASH,:store_id=>param[:store_id],:customer_id=>param[:customer_id],
          :car_num_id=>param[:car_num_id]).where(sql)
        unless orders.blank?
          order_ids,total_card,sort_orders,is_suit = orders.map(&:id),0,[],false
          total_name,revist,sv_prod,send_orders,customer_p,order_points = {},{},{},{},{},{},{}
          send_orders = orders.inject({}){|h,o|h[o.id]=o;h}
          cprs = CPcardRelation.joins(:package_card).select("*").where(:customer_id=>param[:customer_id],:order_id=>order_ids,
            :status=>CPcardRelation::STATUS[:INVALID])
          loss_orders = param[:pay_order] && param[:pay_order][:loss_ids] ?  param[:pay_order][:loss_ids] : {}
          clear_value = param[:pay_order] && param[:pay_order][:clear_value] ? param[:pay_order][:clear_value].to_f : 0
          order_pays = OrderPayType.search_pay_order(order_ids)
          prods = OrderProdRelation.joins(:product).where(:order_id=>orders.map(&:id)).select("products.category_id c_id,order_id o_id,product_id p_id,pro_num,name,revist_content")
          prod_ids = prods.inject(Hash.new){|hash,o|hash[o.o_id]=o.c_id;hash}
          order_prod_ids = prods.inject({}){|h,p|h[p.o_id]=p;h}
          prods.group_by{|i|i.o_id}.each{|k,v|revist["#{k}_#{SendMessage::TYPES[:REVIST]}"] = v.map(&:revist_content).compact unless send_orders[k].auto_time.nil?}
          pcard_name = cprs.inject({}){|hash,p|hash[p.order_id] = p.name;hash} #套餐卡名称
          cprs.group_by{|i|i.order_id}.each{|k,v|revist["#{k}_#{SendMessage::TYPES[:REVIST]}"] = v.map(&:revist_content).compact unless send_orders[k].auto_time.nil? ;revist["#{k}_#{SendMessage::TYPES[:WARN]}"]=v.map(&:con_warn).compact unless send_orders[k].warn_time.nil?}
          o_price = orders.inject(Hash.new){|hash,o|hash[o.id]= limit_float(o.price-(loss_orders["#{o.id}"].nil? ? 0 : loss_orders["#{o.id}"].to_f)-(order_pays[o.id] ?  order_pays[o.id] : 0));hash}
          if param[:pay_order] && param[:pay_order][:text]   #如果使用储值卡
            sv_cards = CSvcRelation.joins(:sv_card=>:svcard_prod_relations).where(:id=>param[:pay_order][:text].keys).select("c_svc_relations.*,
            sv_cards.name,sv_cards.store_id,svcard_prod_relations.category_id ci,svcard_prod_relations.pcard_ids pid,sv_cards.id s_id").where("sv_cards.store_id=#{param[:store_id]}")
            sv_pcard = cprs.inject({}){|h,p|h[p.order_id]=p.package_card_id;h}
            sv_cards.each do |ca|
              t_price = 0
              orders.each do |o|
                if (ca.ci and ca.ci.split(',').include? "#{prod_ids[o.id]}") or (ca.pid and ca.pid.split(',').include? "#{sv_pcard[o.id]}")
                  t_price += o_price[o.id]
                  sort_orders << o
                  sv_prod[o.id] ||= []
                  sv_prod[o.id] << ca.id
                end
              end
              if card_price[ca.s_id] > t_price
                is_suit = true
                break
              end
            end
            if is_suit or card_price.values.compact.reduce(:+) > o_price.values.compact.reduce(:+)
              may_pay,msg = false,"储值卡付款超过可付额度！"
            end
          end
          if may_pay
            total_card = card_price.values.compact.reduce(:+)
            total_card ||= 0
            if param[:pay_order] && param[:pay_order][:loss_ids]  #如果有优惠
              loss = param[:pay_order][:loss_ids]
              loss = param[:pay_order][:loss_ids].select{|k,v| !param[:pay_order][:return_ids].include? k}  if param[:pay_order][:return_ids]
              loss_reason = param[:pay_order][:loss_reason]
              loss.each do |k,v|
                order_pay_types <<  OrderPayType.new(:order_id=>k,:price=>v.to_f.round(2),:pay_type=>OrderPayType::PAY_TYPES[:FAVOUR],:second_parm=>loss_reason[k])
              end unless loss.empty?
            end
            cash_price = param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH].nil? ? 0 : limit_float(param[:pay_cash].to_f - param[:second_parm].to_f)
            orders = sort_orders | (orders - sort_orders)
            #统计订单中  提成 和积分
            deducts = cprs.inject({}){|hash,c|hash[c.order_id] =[c.deduct_price+c.deduct_percent,0];order_points[c.order_id]=c.prod_point;hash}
            Order.joins(:order_prod_relations=>:product).select("ifnull(sum((deduct_price+deduct_percent)*pro_num),0) d_sum,
            ifnull(sum((techin_price+techin_percent)*pro_num),0) t_sum,sum(products.prod_point*order_prod_relations.pro_num) point,orders.id o_id").
              where(:"orders.id"=>order_ids).group('orders.id').each{|order|
              deducts[order.o_id] = deducts[order.o_id].nil? ? [order.d_sum,order.t_sum] : [deducts[order.o_id][0]+order.d_sum,order.t_sum]
              order_points[order.o_id] = order_points[order.o_id].nil? ? order.point : order_points[order.o_id]+order.point
            } #分别表示销售提成和技师提成
            orders.each do |o|
              pp = {:product_id => order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].p_id,
                :product_num => order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].pro_num}
              order_parm = {:is_billing => is_billing,:status=>Order::STATUS[:BEEN_PAYMENT]}
              price = o_price[o.id].to_f.round(2)
              if price > 0
                if price <= total_card
                  order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>limit_float(price),:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD]}.merge(pp))
                  sv_prod[o.id].each do |ca|
                    name = order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].name
                    total_name[ca] ||= []
                    total_name[ca] << name
                    total_name[ca] << pcard_name[o.id]
                  end unless sv_prod[o.id].nil?
                  total_card = limit_float(total_card-price)
                  total_card=0 if total_card <0
                else
                  if total_card >0
                    order_pay_types <<  OrderPayType.new({:order_id=>o.id,:price=>total_card,:pay_type=>OrderPayType::PAY_TYPES[:SV_CARD]}.merge(pp))
                    sv_prod[o.id].each do |ca|
                      name = order_prod_ids[o.id].nil? ? nil : order_prod_ids[o.id].name
                      total_name[ca] ||= []
                      total_name[ca] << name
                      total_name[ca] << pcard_name[o.id]
                    end unless sv_prod[o.id].nil?
                  end
                  parms = pp.merge({:order_id=>o.id,:price=>limit_float(price-total_card-clear_value),:pay_type=>param[:pay_type].to_i})
                  if param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CASH]
                    parms.merge!(:pay_cash=>param[:pay_cash],:second_parm=>param[:second_parm])
                    cash_price = limit_float(cash_price-(price-total_card-clear_value))
                  elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:CREDIT_CARD]
                    parms.merge!(:second_parm=>param[:second_parm])
                  elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:IS_FREE]
                    parms.merge!(pp)
                    order_parm[:status]=Order::STATUS[:FINISHED]
                  elsif param[:pay_type].to_i == OrderPayType::PAY_TYPES[:HANG]  #挂账的话就把要付的钱设置为支付金额
                    parms.merge!(:pay_status=>OrderPayType::PAY_STATUS[:UNCOMPLETE])
                  end
                  order_pay_types <<  OrderPayType.new(parms)
                  total_card =0 if total_card >0
                end
              end
              if deducts[o.id]
                deduct = {:front_deduct => deducts[o.id][0],:technician_deduct => deducts[o.id][1]}
                tech_orders =  o.tech_orders
                tech_orders.update_all(:own_deduct =>deduct[:technician_deduct]/tech_orders.length ) unless tech_orders.blank?
                order_parm.merge!(deduct)
              end
              work_order = o.work_orders[0]
              work_order.update_attributes(:status=>WorkOrder::STAT[:COMPLETE])   if work_order && work_order.status == WorkOrder::STAT[:WAIT_PAY]
              o.update_attributes(order_parm) #更新订单 提成 等信息
            end   #更新完订单状态
            OrderPayType.import order_pay_types unless order_pay_types.blank?
            if param[:pay_order] && param[:pay_order][:text]   #使用储值卡更新储值卡余额，并将更新新买储值卡的状态
              message = "#{customer.name}，您好，您的储值卡"
              t_message = []
              CSvcRelation.find(param[:pay_order][:text].keys).each do |c_relation|
                use_price = param[:pay_order][:text][:"#{c_relation.id}"].to_f
                only_price = limit_float(c_relation.left_price - use_price)
                pars = {:left_price=>only_price}
                sv_card = c_relation.sv_card
                cons = total_name[c_relation.id].nil? ? "" : total_name[c_relation.id].compact.uniq.join("、")
                m_msg = "#{sv_card.name}使用#{use_price}元，剩余#{only_price}元,用于支付#{cons}"
                if only_price <= 0 #如果余额不足，则失效该卡
                  pars.merge!(:status=>CSvcRelation::STATUS[:invalid])
                  m_msg += ",此卡已失效，如需使用请重新购买。"
                end
                c_relation.update_attributes(pars)
                t_message << m_msg
                SvcardUseRecord.create(:c_svc_relation_id=>c_relation.id,:types=>SvcardUseRecord::TYPES[:OUT],:use_price=>use_price,
                  :left_price=>only_price,:content=>cons)
              end
              message += t_message.join("，")+"。"
              message_data(param[:store_id],message,customer,nil,MessageRecord::M_TYPES[:USE_SV])
            end
          
            SvcardUseRecord.import CSvcRelation.joins(:sv_card).select("sv_cards.name,c_svc_relations.id c_id,c_svc_relations.left_price").
              where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CSvcRelation::STATUS[:invalid],:"sv_cards.types"=>SvCard::FAVOR[:SAVE]).inject([]) {|arr,csr|
              is_vip = true; arr << SvcardUseRecord.new(:c_svc_relation_id => csr.c_id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,:left_price =>csr.left_price.round(2), :content => "购买"+"#{csr.name}")
            }   #如果是新买储值卡则生成购买记录
            #新买打折卡 储值卡 更新状态为可用
            CSvcRelation.select("*").where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CSvcRelation::STATUS[:invalid]).update_all :status => CSvcRelation::STATUS[:valid], :is_billing => is_billing
            if (customer && customer.is_vip) || is_vip    #积分  积分记录
              points = order_points.values.compact.inject(0){|sum,n|sum+n}
              t_point = customer.total_point.nil? ? points : customer.total_point+points
              customer.update_attributes({:total_point=>t_point,:is_vip=>Customer::IS_VIP[:VIP]})
              Point.import order_points.inject([]){|arr,p| arr << Point.new(:customer_id=>param[:customer_id],:point_num=>p[1],
                  :target_id=>p[0],:target_content=>"购买产品/服务/套餐卡获得积分",:types=>Point::TYPES[:INCOME]) }
            end

            CPcardRelation.where(:customer_id=>param[:customer_id],:order_id=>orders.map(&:id),:status=>CPcardRelation::STATUS[:INVALID]).update_all :status =>CPcardRelation::STATUS[:NORMAL]
            customer_p = Customer.find(orders.map(&:customer_id)).inject({}){|h,c|h[c.id]=c.mobilephone;h}
            messages = []
            revist.each {|k,v|k_type = k.split("_");order =send_orders[k_type[0].to_i];send_time = k_type[1].to_i == SendMessage::TYPES[:REVIST] ? order.auto_time : order.warn_time;
              messages << SendMessage.new({:content=>v.join('\n'),:customer_id=>order.customer_id,:types=>k_type[1],:car_num_id=>order.car_num_id,
                  :phone=>customer_p[order.customer_id],:send_at=>send_time ,:status=>SendMessage::STATUS[:WAITING],:store_id=>order.store_id})}
            SendMessage.import messages unless messages.blank?    #用于自动回访生成信息记录
          end
        end
      end
    end
    return  [may_pay,msg,orders.map(&:id)]
  end

end
