#encoding: utf-8
require 'json'
require "uri"
class Api::NewAppOrdersController < ApplicationController

  #登录后返回数据
  def new_index_list
    #参数store_id
    status = 0
    #orders => 车位施工情况   #订单分组
    work_orders = working_orders params[:store_id]
    if params[:version] && params[:version]=="2.4"
      reserv_count = Reservation.is_normal(params[:store_id],Reservation::TYPES[:RESER]).count
      render :json => {:status => status, :orders => work_orders,:reserv_count=>reserv_count}
    else
      capital_arr = Capital.get_all_brands_and_models
      #stations_count => 工位数目
      station_ids = Station.where("store_id =? and status not in (?) ",params[:store_id], [Station::STAT[:WRONG], Station::STAT[:DELETED]]).select("id, name")
      work_records = WorkRecord.where(:current_day=>Time.now.strftime("%Y-%m-%d").to_datetime,:store_id=>params[:store_id]).inject({}){|h,w|h[w.staff_id]=w.attend_types;h}
      t_staffs = Staff.where(:type_of_w=>Staff::S_COMPANY[:TECHNICIAN],:store_id=>params[:store_id]).valid.select("id,name").inject([]){|arr,s|arr << {:name=>s.name,:id=>s.id,:status=>WorkRecord::ATTEND_YES.include?(work_records[s.id]) ? 1 : 0 }}
      services = Product.is_service.is_normal.commonly_used.where(:store_id => params[:store_id]).select("id, name, sale_price as price")
      render :json => {:status => status, :orders => work_orders, :station_ids => station_ids, :services => services,:total_staffs=>t_staffs,:used_staffs=>work_orders[:used_staffs], :car_info => capital_arr}
    end
  end

  #产品、服务、卡类搜索
  def search
    type = params[:search_type].to_i
    content = params[:search_text]
    #name = content.empty? || content=="" ? "and 1=1" : " and p.name like %#{content.gsub(/[%_]/){|x| '\\' + x}}%"
    store_id = params[:store_id].to_i
    result = []
    sql = [""]
    if type==0  #如果是产品
      sql[0] = "select p.*, m.storage storage from categories c inner join products p on c.id=p.category_id
        inner join prod_mat_relations pmr on p.id=pmr.product_id
        inner join materials m on pmr.material_id=m.id
        where c.types=? and c.store_id=? and p.status=?"
      sql << Category::TYPES[:good] << store_id << Product::IS_VALIDATE[:YES]
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and p.name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      goods = Product.find_by_sql(sql).uniq
      result = goods.inject([]){|h, g|
        a = {}
        a[:id] = g.id.to_s
        a[:name] = g.name
        a[:img_small] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[0]}")
        a[:img_middle] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[2]}")
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[5]}")
        a[:point] = g.prod_point.to_s
        a[:is_added] = g.is_added
        a[:standard] = g.standard
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        a[:num] = g.storage.to_s
        h << a;
        h
      }
    elsif type==1 #如果是服务
      sql[0] = "select p.* from categories c inner join products p on c.id=p.category_id
        where c.types=? and c.store_id=? and p.status=? and p.single_types=?"
      sql << Category::TYPES[:service] << store_id << Product::IS_VALIDATE[:YES] << Product::SINGLE_TYPE[:SIN]
      sql2 = ["select p.* from products p where p.is_service=? and p.store_id=? and p.status=? and p.single_types=?",
        Product::PROD_TYPES[:SERVICE], store_id, Product::IS_VALIDATE[:YES],Product::SINGLE_TYPE[:DOUB]]
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and p.name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      services = []
      s_services = Product.find_by_sql(sql)
      d_services = Product.find_by_sql(sql2)
      services << s_services << d_services
      services = services.flatten
      result = services.inject([]){|h, g|
        a = {}
        a[:id] = g.id.to_s
        a[:name] = g.name
        a[:img_small] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[0]}")
        a[:img_middle] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[2]}")
        a[:img_big] = g.img_url.nil? ||  g.img_url.empty? ? "" : g.img_url.gsub("img#{g.id}", "img#{g.id}_#{Constant::P_PICSIZE[5]}")
        a[:point] = g.prod_point.to_s
        a[:price] = g.sale_price.to_s
        a[:desc] = g.description
        a[:s_type] = g.single_types.to_s
        a[:num] = 99
        h << a
        h
      }
    elsif type==2 #如果是卡类
      chains_id = StoreChainsRelation.find_by_sql(["select distinct(scr.chain_id) from store_chains_relations scr
      inner join chains c on scr.chain_id=c.id where scr.store_id = ? and c.status=?", store_id, Chain::STATUS[:NORMAL]])
      .map(&:chain_id)
      stores_id = StoreChainsRelation.find_by_sql(["select distinct(scr.store_id) from store_chains_relations scr
      inner join stores s on scr.store_id=s.id where scr.chain_id in (?) and s.status in (?)", chains_id,
          [Store::STATUS[:OPENED],Store::STATUS[:DECORATED]]]).map(&:store_id) #获取该门店所有的连锁店
      if stores_id.blank?   #若该门店无其他连锁店
        sql[0] = "select * from sv_cards where store_id = ? and status = ?"
        sql << store_id << SvCard::STATUS[:NORMAL]
      else    #若该门店有其他连锁店
        sql[0] = "select * from sv_cards where ((store_id=? and use_range=?) or (store_id in (?) and use_range = ?)) and
      status=?"
        sql << store_id << SvCard::USE_RANGE[:LOCAL] << stores_id << SvCard::USE_RANGE[:CHAINS] << SvCard::STATUS[:NORMAL]
      end
      unless content.nil? || content.empty? || content == ""
        sql[0] += " and name like ?"
        sql << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      sv_cards = SvCard.find_by_sql(sql)    #获取该门店的优惠卡及其同连锁店下面的门店的使用范围为连锁店的优惠卡
      sc_records = sv_cards.inject([]){|h, s|
        a = {}
        a[:id] = s.id.to_s
        a[:name] = s.name
        a[:img_small] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[2]}")
        a[:img_middle] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[1]}")
        a[:img_big] = s.img_url.nil? ||  s.img_url.empty? ? "" : s.img_url.gsub("img#{s.id}", "img#{s.id}_#{Constant::SVCARD_PICSIZE[3]}")
        a[:price] = s.price.to_s
        a[:type] = s.types.to_s
        a[:desc] = s.description
        if s.types.to_i==SvCard::FAVOR[:SAVE] #如果是储值卡，则把冲xx送XX，可以在XX类下消费加入到描述中
          str = ""
          spr = SvcardProdRelation.find_by_sv_card_id(s.id)
          if spr && spr.category_id
            ct = Category.find_by_sql(["select name from categories where id in (?)", spr.category_id.split(",")]).map(&:name)
            str += "充"+spr.base_price.to_s+"送"+spr.more_price.to_s+"\n"
            str += "适用类型：\n"
            pn = []
            ct.each do |c|
              pn << c
            end
            str += pn.join("\n")
          end
          a[:products] = pn
          a[:desc] = str
        else   #如果是打折卡，则要关联他的products以及对应的折扣
          str = ""
          pids = SvcardProdRelation.where(["sv_card_id = ?", s.id]) #找到该打折卡关联的产品
          if pids
            spr = pids.inject({}){|h, s|h[s.product_id]=s.product_discount;h} #{1 => XXX折， 2 => XXX折}
            pname = Product.where(["id in (?)", pids.map(&:product_id).uniq]).inject({}){|h, p|h[p.id] = p.name;h} #{1 => "XXX", 2 => "XXX"}
            pn = []
            pn2 = []
            pname.each do |k, v|
              pn << v.to_s + "-" + (spr[k].to_i*0.1).to_s+"折"
              pn2 << {:name => v, :discount => (spr[k].to_i*0.1).to_s+"折"}
            end
            str += pn.join("\n")
            a[:products] = pn2
            a[:desc] = str
          end
        end
        h << a;
        h
      }

      #获取该门店所有的套餐卡及其所关联的物料
      sql2 = ["select p.* from package_cards p
        where p.store_id=? and ((p.date_types=?) or (p.date_types=? and NOW()<=p.ended_at)) and p.status=?",
        store_id, PackageCard::TIME_SELCTED[:END_TIME],
        PackageCard::TIME_SELCTED[:PERIOD], PackageCard::STAT[:NORMAL]]
      unless content.nil? || content.empty? || content == ""
        sql2[0] += " and p.name like ?"
        sql2 << "%#{content.strip.gsub(/[%_]/){|x| '\\' + x}}%"
      end
      p_cards = PackageCard.find_by_sql(sql2)
      p_records = []
      if p_cards
        p_records = p_cards.inject([]){|h, p|
          str2 = ""
          a = {}
          a[:id] = p.id.to_s
          a[:name] = p.name.to_s
          a[:img_small] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::C_PICSIZE[2]}")
          a[:img_middle] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::C_PICSIZE[1]}")
          a[:img_big] = p.img_url.nil? ||  p.img_url.empty? ? "" : p.img_url.gsub("img#{p.id}", "img#{p.id}_#{Constant::C_PICSIZE[3]}")
          a[:price] = p.price.to_s
          a[:type] = "2"
          a[:point] = p.prod_point.to_s
          name_and_num = PcardProdRelation.find_by_sql(["select ppr.product_num, p.name from pcard_prod_relations ppr inner join products p on
         ppr.product_id=p.id where ppr.package_card_id=?", p.id])
          str2 += name_and_num.inject([]){|h, n|h << n.name.to_s+"-"+n.product_num.to_s+"次";h}.join("\n") if name_and_num
          a[:products] = name_and_num.inject([]){|h, n|h << {:name => n.name.to_s, :num => n.product_num.to_s+"次"};h} if name_and_num
          a[:desc] = str2
          h << a;
          h
        }
      end
      result = [sc_records + p_records].flatten
    end
    if result.blank?
      status = 0
      msg = "没有找到符合条件的记录"
    else
      status = 1
      msg = "查找成功!"
    end
    render :json => {:status => status, :msg => msg, :result => result}
  end

  #生成订单
  def make_order2
    #参数params[:content]类型：id_count_search_type_type(选择的商品id_数量_产品/服务/卡_储值卡/打折卡/套餐卡)
    pram_str = params[:content].split("-") if params[:content]
    status = 1
    msg = ""
    sv_cards = []
    p_cards = []
    sales = []
    Customer.transaction do
      customer = CarNum.get_customer_info_by_carnum(params[:store_id], params[:num])
      is_new_cus = 0
      prod_type = 0
      if customer.nil?
        #如果是新的车牌，则要创建一个空白的客户和车牌，以及客户-门店、客户-车牌关联记录
        customer = Customer.create(:status => Customer::STATUS[:NOMAL], :property => Customer::PROPERTY[:PERSONAL],
          :allowed_debts => Customer::ALLOWED_DEBTS[:NO],:store_id=>params[:store_id])
        car_num = CarNum.where(:num =>params[:num]).first
        car_num = CarNum.create(:num => params[:num]) if car_num.nil?
        customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
        customer.save
        is_new_cus = 1
      end
      if params[:is_purpose_order].to_i == 0  # 1代表保存意向单 0 代表不保存
        #创建订单
        if pram_str[2].to_i != 2  #如果是产品或者服务
          if is_new_cus == 0
            #该用户所购买的打折卡及其所支持的产品或服务
            sv_cards = CSvcRelation.get_customer_discount_cards(customer.customer_id,params[:store_id].to_i)
            #该用户所购买的套餐卡及其所支持的产品或服务
            p_cards = CPcardRelation.get_customer_package_cards(customer.customer_id, params[:store_id].to_i, pram_str[0].to_i)
            #该用户所购买的储值卡及其所支持的产品或服务类型
            save_cards = CSvcRelation.get_customer_supposed_save_cards(customer.customer_id, params[:store_id].to_i, pram_str[0].to_i)
          end
          create_result = OrderProdRelation.make_record(pram_str[0].to_i, pram_str[1].to_i, params[:user_id].to_i,
            is_new_cus == 0 ? customer.customer_id : customer.id,  is_new_cus == 0 ? customer.car_num_id : car_num.id, params[:store_id].to_i)
          status = create_result[0]
          msg = create_result[1]
          product = create_result[2]
          order = create_result[3]
          prod_type = 1 if product.is_service
          #获取所有该产品相关的活动
          s = Order.get_sale_by_product(product, order.car_num_id) if product and order
          sales = s
        else  #如果选的是卡类
          prod_type = 2
          card_type = 0
          if pram_str[3].to_i == 0 || pram_str[3].to_i == 1    #如果选的是打折卡或储值卡
            card = SvCard.find_by_id(pram_str[0].to_i)
          else
            card = PackageCard.find_by_id(pram_str[0].to_i)
            pmrs = PcardMaterialRelation.find_by_sql(["select pmr.material_num mnum, m.storage storage from pcard_material_relations
                 pmr inner join materials m on pmr.material_id=m.id where pmr.package_card_id=?", card.id])
            pmrs.each do |pmr|
              if pmr.mnum > pmr.storage
                status = 0
                msg = "您购买的套餐卡所需的物料库存不足!"
                break
              end
            end if pmrs
            card_type = 1
          end
          if card
            if status == 1
              order = Order.create({
                  :code => MaterialOrder.material_order_code(params[:store_id].to_i),
                  :car_num_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
                  :status => Order::STATUS[:WAIT_PAYMENT],
                  :price => card.price,
                  :is_billing => false,
                  :front_staff_id => params[:user_id],
                  :customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
                  :store_id => params[:store_id],
                  :is_visited => Order::IS_VISITED[:NO],
                  :types => Order::TYPES[:PRODUCT],
                  :auto_time => card_type==1 && card.is_auto_revist ? Time.now + card.auto_time.to_i.hours : nil,
                  :warn_time => card_type==1 && card.auto_warn ? Time.now + card.time_warn.to_i.days : nil
                })
              if pram_str[3].to_i == 0 ||  pram_str[3].to_i == 1   #如果是选的打折卡或储值卡，则要把这个卡加到该客户sv_cards中
                if  pram_str[3].to_i == 0   #如果是打折卡
                  CSvcRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
                    :sv_card_id => card.id, :order_id => order.id, :status => CSvcRelation::STATUS[:invalid])
                  items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
                           inner join products p on spr.product_id=p.id where spr.sv_card_id=?", card.id])
                  arr = []
                  items.each do |i|
                    i_hash = {}
                    i_hash[:pid] = i.id
                    i_hash[:pname] = i.name
                    i_hash[:pprice] = i.sale_price
                    i_hash[:pdiscount] = i.product_discount.to_i*0.1
                    i_hash[:selected] = 1
                    arr << i_hash
                  end
                  sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
                    :show_price => card.price, :products => arr}
                elsif pram_str[3].to_i ==1  #如果是储值卡
                  money = card.svcard_prod_relations.first
                  if money.category_id
                    CSvcRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id,:sv_card_id => card.id,
                      :order_id => order.id, :status => CSvcRelation::STATUS[:invalid],:total_price => money.base_price+money.more_price,
                      :left_price => money.base_price+money.more_price,
                      :id_card=>add_string(8,CSvcRelation.joins(:customer).where(:"customers.store_id"=>params[:store_id]).count+1))
                    arr = []
                    money.category_id.split(",").each do |i|
                      i_hash = {}
                      i_hash[:pid] = i.to_i
                      category = Category.find_by_id(i.to_i)
                      i_hash[:pname] = category.nil? ? nil : category.name
                      arr << i_hash
                    end
                    sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
                      :show_price => card.price, :products => arr}
                  else
                    status = 0
                    msg = "该卡没有设置适用的项目"
                  end
                end
              elsif pram_str[3].to_i == 2 #如果是选的套餐卡，则要把这个套餐卡加到该客户p_cards中,并且扣除该套餐卡对应的物料(如果有的话)
                pitems = PcardProdRelation.find_by_sql(["select ppr.product_num num, p.name name,p.id id, p.sale_price sale_price
             from pcard_prod_relations ppr inner join products p on ppr.product_id=p.id where ppr.package_card_id=?", card.id])
                pstr = ""
                b,c = [],[]
                pitems.each do |pi|
                  b << "#{pi.id}-#{pi.name}-#{pi.num}"
                  c << {:proid => pi.id, :proname => pi.name, :pro_left_count => pi.num, :selected => 1, :pprice => pi.sale_price}
                end
                pstr = b.join(",")
                ended_at = card.date_types==PackageCard::TIME_SELCTED[:PERIOD] ? card.ended_at : Time.now + card.date_month.to_i.days
                CPcardRelation.create(:customer_id => is_new_cus==0 ? customer.customer_id : customer.id,
                  :package_card_id => card.id, :ended_at => ended_at.strftime("%Y-%m-%d")+" 23:59:59", :status => CPcardRelation::STATUS[:INVALID], :content => pstr,
                  :price => card.price, :order_id => order.id)
                pmr = PcardMaterialRelation.find_by_package_card_id(card.id)
                material = Material.find_by_id(pmr.material_id) if pmr
                Material.update_storage(pmrs.material_id,material.storage - pmr.material_num,params[:user_id],"pad销售套餐卡扣物料",nil,order) if material #更新库存并生成出库记录
                p_cards << {:pid => card.id, :pname => card.name, :pprice => card.price, :ptype => 2, :is_new => 1,
                  :show_price => card.price, :products => c}
              end
            end
          else
            status = 0
            msg = "没有找到所选择的卡!"
          end
        end

        if status ==1
          #获取所有的车品牌/型号
          capital_arr = status==0 ? [] : Capital.get_all_brands_and_models
          p = []
          unless product.nil?
            p << {:id => product.id, :name => product.name, :count => pram_str[1].to_i,
              :price => product.single_types == Product::SINGLE_TYPE[:SIN] ? product.sale_price.to_f : 0,
              :show_price => product.single_types == Product::SINGLE_TYPE[:SIN] ? product.sale_price.to_f * pram_str[1].to_i : 0}
          end
        end
        work_orders = working_orders params[:store_id]
        normal_return = { :orders => work_orders, :msg => msg, :product => p, :sales => sales,:sv_cards => sv_cards,
          :p_cards => p_cards, :save_cards => save_cards.nil? ? [] : save_cards, :car_info => capital_arr,:prod_type => prod_type}
      elsif params[:is_purpose_order].to_i > 0 #0 产品 1 服务 2 套餐卡 3 打折卡 4 储值卡
        prod_types =  pram_str[2].to_i != 2 ? pram_str[2].to_i : pram_str[3].to_i == 2 ? 2 : pram_str[3].to_i+3
        types = params[:is_purpose_order].to_i == 1 ? Reservation::TYPES[:PURPOSE] : Reservation::TYPES[:RESER]
        Reservation.create(:code=>MaterialOrder.material_order_code(params[:store_id]),
          :car_num_id=>is_new_cus==0 ? customer.car_num_id : car_num.id,
          :customer_id=>is_new_cus==0 ? customer.customer_id : customer.id,
          :store_id=>params[:store_id],:res_time=>Time.now,:types=>types,:prod_types=>prod_types,
          :prod_id =>pram_str[0].to_i,:prod_price =>pram_str[-1],:prod_num => pram_str[1].to_i,
          :staff_id=>params[:user_id],:status=>Reservation::STATUS[:normal] )
        normal_return = {}
      end
      order_infos = {
        :cid => is_new_cus==0 ? customer.customer_id : customer.id,
        :cname => is_new_cus==0 ? customer.name : nil,
        :csex => is_new_cus==0 ? customer.sex : 1,
        :cmoilephone => is_new_cus==0 ? customer.mobilephone : nil,
        :cproperty => customer.property.to_i,
        :cgroup_name => customer.property.to_i==0 ? nil : customer.group_name,
        :cnum => params[:num],
        :cnum_id => is_new_cus==0 ? customer.car_num_id : car_num.id,
        :cmodel => is_new_cus==0 ? customer.model_name : nil,
        :cbrand => is_new_cus==0 ? customer.brand_name : nil,
        :cbirthday => (is_new_cus==1 || customer.birth.nil?)  ?  nil : customer.birth,
        :cbuyyear => is_new_cus==0 ? customer.year : nil,
        :cdistance => is_new_cus==0 ? customer.distance : nil,
        :oid => order.nil? ? nil : order.id,
        :ocode => order.nil? ? nil : order.code,
        :oprice => order.nil? ? nil : order.price,
        :opname => product.nil? ? (card.nil? ? nil : card.name) : product.name
      }
      render :json => {:status => status, :order_infos => order_infos}.merge(normal_return)
    end
  end

  #快速下单
  def quickly_make_order
    status = 1
    msg = ""
    sid = params[:service_id].to_i
    num = params[:num]
    store_id = params[:store_id].to_i
    user_id = params[:user_id].to_i
    Customer.transaction do
      customer = CarNum.get_customer_info_by_carnum(store_id, num)
      is_new_cus = 0
      if customer.nil?
        #如果是新的车牌，则要创建一个空白的客户和车牌，以及客户-门店、客户-车牌关联记录
        customer = Customer.create(:status => Customer::STATUS[:NOMAL],:store_id => store_id)
        car_num = CarNum.where(:num =>params[:num]).first
        car_num = CarNum.create(:num => params[:num]) if car_num.nil?
        customer.customer_num_relations.create({:customer_id => customer.id, :car_num_id => car_num.id})
        customer.save
        is_new_cus = 1
      end
      create_result = OrderProdRelation.make_record(sid, 1, user_id,
        is_new_cus == 0 ? customer.customer_id : customer.id,  is_new_cus == 0 ? customer.car_num_id : car_num.id, store_id)
      status = create_result[0]
      msg = create_result[1]
      work_orders = working_orders store_id
      render :json => {:status => status, :msg => msg, :orders => work_orders}
    end
  end
  #同步pad上面的订单和客户信息
  def sync_orders_and_customer
    sync_info = JSON.parse(params[:syncInfo])
    orders = sync_info["order"]
    Order.transaction do
      orders.each do |o|
        status = o["status"].to_i #0取消订单，1已付款
        order = Order.find_by_id(o["order_id"].to_i)
        if status==0    #0取消订单
          oprs = order.order_prod_relations
          oprs.each do |opr|    #如果有对应的物料，则要将这些物料对应的数量补上
            pid = opr.product_id
            pnum = opr.pro_num
            pmrs = ProdMatRelation.where(["product_id = ?", pid])
            pmrs.each do |pmr|
              mnum = pmr.material_num
              mid = pmr.material_id
              mater = Material.find_by_id(mid)
              mater.update_attribute("storage", mater.storage+(pnum * mnum))
            end if pmrs
          end if oprs
          order.update_attributes(:status  => Order::STATUS[:RETURN])
        elsif status==1 #已付款
          customer = Customer.find_by_id(o["customer_id"].to_i)
          customer.update_attributes(:name => o["userName"].nil? ? nil : o["userName"].strip, :mobilephone => o["phone"].nil? ? nil : o["phone"].strip,
            :birthday => o["birth"].nil? ||o["birth"].strip=="" ? nil :o["birth"], :sex => o["sex"].to_i,
            :property => o["cproperty"].to_i, :group_name => o["cproperty"].to_i==0 ? nil : o["cgroup_name"])
          car_num = CarNum.find_by_id(o["car_num_id"].to_i)
          car_num.update_attributes(:car_model_id => o["brand"].nil? || o["brand"].split("_")[1].nil? ? nil : o["brand"].split("_")[1].to_i,
            :buy_year => o["year"], :distance => o["cdistance"].nil? ? nil : o["cdistance"].to_i)
          if o["pay_type"].to_i == 0 #现金付款
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH], :price => o["total_price"].to_f)
          elsif o["pay_type"].to_i ==5 #免单
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType[:IS_FREE], :price => o["total_price"].to_f)
          end
          order.update_attributes(:status  => Order::STATUS[:BEEN_PAYMENT], :is_pleased => o["is_please"].to_i, :is_billing => o["billing"].to_i)
          if (o["reason"] && o["reason"].strip != "") || (o["request"] && o["request"].strip != "")
            Complaint.create(:order_id => order.id, :reason => o["reason"], :suggestion => o["request"],
              :status => Complaint::STATUS[:UNTREATED], :types => Complaint::TYPES[:OTHERS])
          end
          sale_id = []
          c_pcard_relation_id = []
          c_svc_relation_id = []
          prods = o["prods"].split(",") #[0_255_2_200, 1_47_255=20, 2_322_0_0_16=200_128, 3_111_0_16=2_147]
          prods.each do |prod|  #1_47_255=20
            if prod.split("_")[0].to_i==1 #如果有活动   [1,47,255=20]
              arr = prod.split("_")
              sale_id << arr[1].to_i  #[1,47,255=20]
              arr.each do |a|  #[1,47,255=20]
                if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                  OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => a.split("=")[1].to_f,
                    :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                end
              end
            elsif prod.split("_")[0].to_i==2  #如果有优惠卡 2_322_0_0_16=200_128
              arr = prod.split("_")
              sid = arr[1].to_i
              if arr[2].to_i==0 #如果是打折卡
                arr.each do |a|
                  if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                    OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                      :price => a.split("=")[1].to_f, :product_id => a.split("=")[0].to_i, :production_num => a.split("=")[2].to_i)
                  end
                end
                if arr[3].to_i==0 #如果是用户已有的打折卡
                  csrid = arr[-1].to_i  #用户-打折卡关联id
                  c_svc_relation_id << csrid
                elsif arr[3].to_i==1  #如果是用户刚买的打折卡，则要简历客户-打折卡关系记录
                  csr = CSvcRelation.create(:customer_id => customer.id, :sv_card_id => sid, :is_billing => o["billing"].to_i,
                    :status => CSvcRelation::STATUS[:valid], :order_id => order.id)
                  c_svc_relation_id << csr.id
                end
              elsif  arr[2].to_i==1 && arr[3].to_i==1 #如果是新买的储值卡，则创建储值卡-用户关联关系
                save_c = SvCard.find_by_sql(["select s.id sid, s.name sname, spr.base_price bprice, spr.more_price mprice from sv_cards s
                inner join svcard_prod_relations spr on s.id=spr.sv_card_id where s.id=?", sid])[0]
                csr = CSvcRelation.create(:customer_id => customer.id, :sv_card_id => save_c.sid, :total_price => save_c.bprice.to_f + save_c.mprice.to_f,
                  :left_price => save_c.bprice.to_f + save_c.mprice.to_f, :is_billing => o["billing"].to_i, :order_id => order.id,
                  :status => CSvcRelation::STATUS[:valid], :password => Digest::MD5.hexdigest(arr[-1].strip))
                SvcardUseRecord.create(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,
                  :left_price => save_c.bprice.to_f + save_c.mprice.to_f, :content => "购买"+"#{save_c.sname}")
              end
            elsif prod.split("_")[0].to_i==3  #如果是套餐卡
              arr = prod.split("_")
              pid = arr[1].to_i
              selected_prods = arr.inject({}){|a, s|   #[2-5,56-1]
                if !s.split("=")[1].nil?
                  apid = s.split("=")[0].to_i
                  apcount = s.split("=")[1].to_i
                  a[apid] = apcount
                end;
                a
              }
              if arr[2].to_i==0 #如果是用户已有的套餐卡,则要扣除购买的产品对应的数量
                cprid = arr[-1].to_i
                cpr = CPcardRelation.find_by_id(cprid)
                cpr_content = cpr.content.split(",") #[2-产品1-22,56-服务2-3, 17-产品2-3]
                a = []
                (cpr_content ||[]).each do |cc|
                  ccid = cc.split("-")[0].to_i
                  ccname = cc.split("-")[1]
                  cccount = cc.split("-")[2].to_i
                  if selected_prods[ccid]
                    a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                  else
                    a << "#{ccid}-#{ccname}-#{cccount}"
                  end
                end
                cpr.update_attribute("content", a.join(","))
                c_pcard_relation_id << cpr.id
              else  #如果是用户刚买的套餐卡，则要扣掉刚买的产品，并且生成客户-套餐卡关系
                pc_items = PcardProdRelation.find_by_sql(["select p.id, p.name, ppr.product_num num from package_cards pc inner join pcard_prod_relations
             ppr on pc.id=ppr.package_card_id inner join products p on ppr.product_id=p.id where pc.id=?", pid])
                cpr_content = pc_items.inject([]){|a, p|a << "#{p.id}-#{p.name}-#{p.num}";a}  #[2-产品1-22,56-服务2-3, 17-产品2-3]
                a = []
                (cpr_content ||[]).each do |cc|
                  ccid = cc.split("-")[0].to_i
                  ccname = cc.split("-")[1]
                  cccount = cc.split("-")[2].to_i
                  if selected_prods[ccid]
                    a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                  else
                    a << "#{ccid}-#{ccname}-#{cccount}"
                  end
                end
                pcard = PackageCard.find_by_id(pid)
                if pcard.date_types == PackageCard::TIME_SELCTED[:END_TIME]  #根据套餐卡的类型设置截止时间
                  ended_at = (Time.now + (pcard.date_month).days).to_datetime
                else
                  ended_at = pcard.ended_at
                end
                cpr = CPcardRelation.create(:customer_id => customer.id, :package_card_id => pcard.id, :ended_at => ended_at,
                  :status => CPcardRelation::STATUS[:NORMAL], :content => a.join(","), :price => pcard.price, :order_id => order.id)
                c_pcard_relation_id << cpr.id
              end
              (selected_prods).each do |k, v|
                OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpr.id, :product_id => k, :product_num => v)
                product = Product.find_by_id(k)
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD],
                  :price => product.sale_price * v, :product_id => k, :product_num => v)
              end if selected_prods.length > 0
            end
          end if prods
        elsif status == 2    #未付款,只是客户不满意，提出投诉评论
          if (o["request"] || o["reason"]) && o["is_please"].to_i == 0
            Complaint.create(:order_id => order.id, :reason => o["reason"], :suggestion => o["request"],
              :status => Complaint::STATUS[:UNTREATED], :types => Complaint::TYPES[:OTHERS])
            order.update_attributes(:status => Order::STATUS[:WAIT_PAYMENT], :is_pleased => o["is_please"].to_i)
          end
        end
      end
      work_orders = working_orders sync_info["store_id"].to_i
      render :json => {:status => 1, :orders => work_orders}
    end
  end

  

  #施工完成 -> 等待付款
  def work_order_finished
    #work_order_id
    work_order = WorkOrder.find_by_id(params[:work_order_id])
    
    if work_order
      status = work_order.status==WorkOrder::STAT[:WAIT_PAY]? 0 : 1
      #0:"此车等待付款"1:未付款
      work_order.arrange_station
    else
      #"工单未找到"
      status = 2
    end
    work_orders = working_orders params[:store_id]
    render :json => {:status => status, :orders => work_orders}
  end

  #准备order相关内容付款
  def order_info
    status = 1
    msg = ""
    oid = params[:order_id].to_i
    store_id = params[:store_id].to_i
    Order.transaction do
      order = Order.find_by_id(oid)
      if order.status == Order::STATUS[:BEEN_PAYMENT]
        status = 0
        msg = "该订单已付款!"
        work_orders = working_orders store_id
        render :json => {:status => status, :msg => msg, :orders => work_orders}
      else
        oprs = order.order_prod_relations
        opcsvc = CSvcRelation.find_by_order_id_and_status(order.id, CSvcRelation::STATUS[:invalid])
        opcpc = CPcardRelation.find_by_order_id_and_status(order.id, CPcardRelation::STATUS[:INVALID])
        customer = Customer.find_by_id(order.customer_id)
        car_num = CarNum.find_by_id(order.car_num_id)
        car_model = car_num.nil? || car_num.car_model_id.nil? ? nil : CarModel.find_by_id(car_num.car_model_id)
        car_brand = car_model.nil? || car_model.car_brand_id.nil? ? nil : CarBrand.find_by_id(car_model.car_brand_id)
        sv_cards = []
        p_cards = []
        save_cards = []
        sales = []
        opname = []
        p = []
        prod_type = 0
        if oprs.any? #如果该订单购买的是产品或者服务
          #该用户所购买的打折卡及其所支持的产品或服务
          sv_cards = CSvcRelation.get_customer_discount_cards(customer.id,store_id)
          #该用户所购买的套餐卡及其所支持的产品或服务
          p_cards = CPcardRelation.get_customer_package_cards(customer.id, store_id, oprs[0].product_id)
          #该用户所购买的储值卡及其所支持的产品或服务类型
          oprs.each do |opr|
            sc = CSvcRelation.get_customer_supposed_save_cards(customer.id, store_id,opr.product_id)
            save_cards << sc
            product = Product.find_by_id(opr.product_id)
            if product.is_service
              prod_type = 1
            end
            unless product.nil?
              p << {:id => product.id, :name => product.name, :count => opr.pro_num,
                :price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : product.sale_price,
                :show_price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : product.sale_price.to_f * opr.pro_num}
            end
            #获取支持该产品的活动
            opname << product.name
            s = Order.get_sale_by_product(product, order.car_num_id) if product
            sales << s
          end
          sales = sales.flatten(1).uniq
          save_cards = save_cards.flatten.uniq
        elsif opcsvc  #如果购买的是储值卡或者打折卡
          card = SvCard.find_by_id(opcsvc.sv_card_id)
          prod_type = 2
          if card && card.types == SvCard::FAVOR[:DISCOUNT]
            items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", card.id])
            a = []
            items.each do |i|
              hash = {}
              hash[:pid] = i.id
              hash[:pname] = i.name
              hash[:pprice] = i.sale_price
              hash[:pdiscount] = i.product_discount.to_i*0.1
              hash[:selected] = 1
              a << hash
            end
            sv_cards << {:csrid => opcsvc.id, :svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
              :show_price => card.price, :products => a}
          elsif  card && card.types == SvCard::FAVOR[:SAVE]
            item = SvcardProdRelation.where(["sv_card_id = ? ", card.id]).first
            arr = []
            item.category_id.split(",").each do |i|
              i_hash = {}
              i_hash[:pid] = i.to_i
              category = Category.find_by_id(i.to_i)
              i_hash[:pname] = category.nil? ? nil : category.name
              arr << i_hash
            end
            sv_cards << {:svid => card.id, :svname => card.name, :svprice => card.price, :svtype => card.types, :is_new => 1,
              :show_price => card.price, :products => arr}
          end
        elsif opcpc #如果是套餐卡
          card = PackageCard.find_by_id(opcpc.package_card_id)
          prod_type = 2
          pitems = PcardProdRelation.find_by_sql(["select ppr.product_num num, p.name name,p.id id, p.sale_price sale_price
             from pcard_prod_relations ppr inner join products p on ppr.product_id=p.id where ppr.package_card_id=?", card.id])
          c = []
          pitems.each do |pi|
            c << {:proid => pi.id, :proname => pi.name, :pro_left_count => pi.num, :selected => 1, :pprice => pi.sale_price}
          end
          p_cards << {:pid => card.id, :pname => card.name, :pprice => card.price, :ptype => 2, :is_new => 1,
            :show_price => card.price, :products => c, :status => 0}
        end
    
        order_infos = {
          :cid => customer.id,
          :cname =>customer.name,
          :csex => customer.sex,
          :cmoilephone =>customer.mobilephone,
          :cproperty => customer.property,
          :cgroup_name => customer.property.to_i == 0 ? nil : customer.group_name,
          :cnum => car_num.num,
          :cnum_id => car_num.id,
          :cmodel => car_model.nil? ? nil : car_model.name,
          :cbrand => car_brand.nil? ? nil : car_brand.name,
          :cbirthday => customer.birthday.nil? ? nil : customer.birthday.strftime("%Y-%m-%d"),
          :cbuyyear => car_num.nil? ? nil : car_num.buy_year,
          :cdistance => car_num.nil? ? nil : car_num.distance,
          :oid => order.nil? ? nil : order.id,
          :ocode => order.nil? ? nil : order.code,
          :oprice => order.nil? ? nil : order.price,
          :oplease => order.nil? ? nil : order.is_pleased,
          :opname => opname.join(",")
        }
        render :json => {:status => status, :msg => msg, :order_infos => order_infos,  :product => p, :prod_type => prod_type,
          :sales => sales, :sv_cards => sv_cards, :p_cards => p_cards, :save_cards => save_cards}
      end
    end
  end

  #套餐卡下单-订单详情
  def pcard_order_info
    status = 1
    msg = ""
    oid = params[:order_id].to_i
    store_id = params[:store_id].to_i
    Order.transaction do
      prod_type = 0
      order = Order.find_by_id(oid)
      opr = order.order_prod_relations.first
      product = Product.find_by_id(opr.product_id)
      p = []
      p << {:id => product.id, :name => product.name, :count => opr.pro_num,
        :price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : product.sale_price,
        :show_price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : product.sale_price.to_f * opr.pro_num}
      if product.is_service
        prod_type = 1
      end
      customer = Customer.find_by_id(order.customer_id)
      cpr_id = order.c_pcard_relation_id.split(",")[0].to_i
      cpr = CPcardRelation.find_by_id(cpr_id)
      cpcard = PackageCard.find_by_id(cpr.package_card_id)
      ha = {}
      ha[:cprid] = cpr_id
      ha[:pid] = cpcard.id
      ha[:pname] = cpcard.name
      ha[:pprice] = cpcard.price
      ha[:ptype] = 2
      ha[:is_new] = 0
      ha[:show_price] = 0
      ha[:status] = 1
      ha[:products] = []
      items = cpr.content.split(",")
      items.each do |i|           #i=447-0927mat1-2
        hash = {}
        hash[:proid] = i.split("-")[0]
        hash[:proname] = i.split("-")[1]
        hash[:pro_left_count] = i.split("-")[2]
        hash[:selected] = 1
        pprod = Product.find_by_id(i.split("-")[0].to_i)
        hash[:pprice] = pprod.nil? ? nil : pprod.sale_price
        ha[:products] << hash
      end if items
      car_num = CarNum.find_by_id(order.car_num_id)
      car_model = car_num.nil? || car_num.car_model_id.nil? ? nil : CarModel.find_by_id(car_num.car_model_id)
      car_brand = car_model.nil? || car_model.car_brand_id.nil? ? nil : CarBrand.find_by_id(car_model.car_brand_id)
      order_infos = {
        :cid => customer.id,
        :cname =>customer.name,
        :csex => customer.sex,
        :cmoilephone =>customer.mobilephone,
        :cproperty => customer.property,
        :cgroup_name => customer.property.to_i == 0 ? nil : customer.group_name,
        :cnum => car_num.num,
        :cnum_id => car_num.id,
        :cmodel => car_model.nil? ? nil : car_model.name,
        :cbrand => car_brand.nil? ? nil : car_brand.name,
        :cbirthday => customer.birthday.nil? ? nil : customer.birthday.strftime("%Y-%m-%d"),
        :cbuyyear => car_num.nil? ? nil : car_num.buy_year,
        :cdistance => car_num.nil? ? nil : car_num.distance,
        :oid => order.nil? ? nil : order.id,
        :ocode => order.nil? ? nil : order.code,
        :oprice => order.nil? ? nil : order.price
      }
      render :json => {:status => status, :msg => msg, :order_infos => order_infos,  :product => p, :prod_type => prod_type,
        :sales => [], :sv_cards => [], :p_cards => [ha], :save_cards => []}
    end
  end

  #付款
  def pay_order
    #prods参数格式: 产品：0_id_count_price 0开头，id，数量，价格总价
    #活动: 1_id_id=price  1开头，活动的id,活动使用的产品(服务)id=活动优惠的价格
    #储值卡 2_id_type_is_new_id_password  2开头，储值卡id，类型(1)，是否是新的，密码
    #打折卡 2_id_type_is_new_id=price_cid 2开头，打折卡id，类型(0)，是否是新的，打折卡打折的产品(服务)id=打折的价格，客户-打折卡关联的id
    #套餐卡 3_id_is_new_id=price_cid    3开头，套餐卡id,是否是新的，套餐卡使用的产品(服务)id=使用的次数，客户-套餐卡关联的id
    #brand: 1_2 brand的id_model的id, userName 客户的name
    Order.transaction do
      customer = Customer.where(:id=>params[:customer_id].to_i,:store_id=>params[:store_id]).first
      order = Order.find_by_id(params[:order_id].to_i)
      work_order = WorkOrder.find_by_order_id(order.id)
      unless Order::OVER_CASH.include?(order.status)
        oprs = order.order_prod_relations
        order.update_attribute("customer_id", customer.id)
        total_price = params[:total_price].to_f
        is_billing = params[:billing].to_i
        pay_type = params[:pay_type].to_i
        is_pleased = params[:is_please].to_i
        is_vip,msg = false,"付款成功!"
        ocid,status = customer.id,0
        prods = params[:prods].split(",") #[0_255_2_200, 1_47_255=20, 2_322_0_0_16=200_128, 3_111_0_16=2_147]
        p_count = prods[0].split("_")[2].to_i
        if pay_type == 0 #现金
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:CASH], :price => total_price,
            :product_id => oprs.blank? ? nil : oprs[0].product_id, :product_num => oprs.blank? ? nil : p_count)
          status = 1
        elsif pay_type==1 #储值卡
          customer_savecard = CSvcRelation.find_by_id(params[:csrid].to_i)
          sv_card = customer_savecard.sv_card
          if customer_savecard
            if customer_savecard.password  == Digest::MD5.hexdigest(params[:password].strip)
              if customer_savecard.left_price >= total_price
                SvcardUseRecord.create(:c_svc_relation_id => customer_savecard.id, :types => SvcardUseRecord::TYPES[:OUT],
                  :use_price => total_price, :left_price => customer_savecard.left_price - total_price,:content => "#{total_price}付费")
                customer_savecard.update_attribute("left_price", customer_savecard.left_price - total_price)
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SV_CARD], :price => total_price,
                  :product_id => oprs.blank? ? nil : oprs[0].product_id, :product_num => oprs.blank? ? nil : p_count)
                customer_savecard.update_attribute("status", CSvcRelation::STATUS[:invalid])  if customer_savecard.left_price <=0
                send_message = "#{customer.name}，您好，您的储值卡#{sv_card.name}使用#{total_price}元，剩余#{customer_savecard.left_price}元。"
                m_types = MessageRecord::M_TYPES[:USE_SV]
                status = 1
              else
                msg = "余额不足!"
              end
            else
              msg = "密码错误!"
            end
          else
            msg = "数据错误!"
          end
        elsif pay_type==5 #免单
          OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:IS_FREE], :price => total_price,
            :product_id => oprs.blank? ? nil : oprs[0].product_id)
          status = 1
        end
        if status ==1
          c_pcard_relation_id,c_svc_relation_id,warns,revist = [],[],[],[]
          deduct_price,techin_price,sale_id = 0,0,0
          prods.each do |prod|  #1_47_255=20
            if prod.split("_")[0].to_i==0 #如果有产品
              arr = prod.split("_")
              product = Product.find_by_id(arr[1].to_i)
              deduct_price = deduct_price + (product.deduct_price.to_f + product.deduct_percent.to_f) * arr[2].to_i
              techin_price = techin_price + (product.techin_price.to_f + product.techin_percent.to_f) * arr[2].to_i
              revist << product.revist_content
            elsif prod.split("_")[0].to_i==1 #如果有活动   [1,47,255=20]
              arr = prod.split("_")
              sale_id = arr[1].to_i  #[1,47,255=20]
              arr.each do |a|  #[1,47,255=20]
                if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                  OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => a.split("=")[1].to_f,
                    :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                end
              end
            elsif prod.split("_")[0].to_i==2  #如果有优惠卡 2_322_0_0_16=200_128
              arr = prod.split("_")
              sid = arr[1].to_i
              if arr[2].to_i==0 #如果是打折卡
                arr.each do |a|
                  if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                    OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                      :price => a.split("=")[1].to_f, :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                  end
                end
                if arr[3].to_i==0 #如果是用户已有的打折卡
                  c_svc_relation_id << arr[-1].to_i  #用户-打折卡关联id
                elsif arr[3].to_i==1  #如果是用户刚买的打折卡，则要更新客户-打折卡关系记录
                  csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", ocid,
                      sid, order.id, CSvcRelation::STATUS[:invalid]]).first
                  if csr.nil?
                    status = 0
                    msg = "数据错误!"
                  else
                    csr.update_attributes(:status => CSvcRelation::STATUS[:valid], :is_billing => is_billing, :customer_id => customer.id)
                    c_svc_relation_id << csr.id
                    is_vip = true    if csr && !customer.is_vip
                  end
                end
              elsif  arr[2].to_i==1 && arr[3].to_i==1 #如果是新买的储值卡，则更新储值卡-用户关联关系
                save_c = SvCard.find_by_id(sid)
                csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", ocid, sid,
                    order.id, CSvcRelation::STATUS[:invalid]]).first
                if csr.nil?
                  status = 0
                  msg = "数据错误!"
                else
                  csr.update_attributes(:status => CSvcRelation::STATUS[:valid], :is_billing => is_billing,:customer_id => customer.id,
                    :password => Digest::MD5.hexdigest(arr[-1].strip))
                  m_types = MessageRecord::M_TYPES[:BUY_SV]
                  card = SvCard.find sid
                  send_message = "#{customer.name}：您好，您购买的储值卡#{card.name},余额为#{csr.left_price}元，密码是#{arr[-1].strip}，请您尽快付款使用。"
                  SvcardUseRecord.create(:c_svc_relation_id => csr.id, :types => SvcardUseRecord::TYPES[:IN], :use_price => 0,
                    :left_price => csr.left_price, :content => "购买"+"#{save_c.name}")
                  is_vip = true if csr && !customer.is_vip
                end
              end
            elsif prod.split("_")[0].to_i==3  #如果是套餐卡
              arr = prod.split("_")
              pid = arr[1].to_i
              acontent,acount = [],true
              prod_id,pname = nil,nil
              selected_prods = arr.inject({}){|h, s|
                if s.split("=")[1]
                  prod_id=s.split("=")[0].to_i
                  h[s.split("=")[0].to_i] = s.split("=")[1].to_i
                end
                h }  #[2-5,56-1]
              if arr[2].to_i==0 #如果是用户已有的套餐卡,则要扣除购买的产品对应的数量
                cprid = arr[-1].to_i
                cpr = CPcardRelation.find_by_id(cprid)
                c_pcard_relation_id << cpr.id
              elsif arr[2].to_i==1  #如果是用户刚买的套餐卡，则要扣掉刚买的产品，并且更新客户-套餐卡关系
                pcard = PackageCard.find_by_id(pid)
                revist << pcard.revist_content  if pcard.revist_content
                warns  << pcard.con_warn        if pcard.con_warn
                deduct_price = deduct_price + (pcard.deduct_price.to_f + pcard.deduct_percent.to_f)
                cpr = CPcardRelation.where(["customer_id=? and package_card_id=? and status=? and order_id=?", ocid,
                    pid, CPcardRelation::STATUS[:INVALID], order.id]).first
                is_vip = true if csr && !customer.is_vip
              end
              cpr_content = cpr.content.split(",")
              (cpr_content ||[]).each do |cc|
                ccid = cc.split("-")[0].to_i
                cccount = cc.split("-")[2].to_i
                if prod_id == ccid
                  cccount -= selected_prods[ccid]
                  pname =  cc.split("-")[1]
                end
                acontent << "#{ccid}-#{cc.split("-")[1]}-#{cccount}"
                acount=false if cccount > 0
              end
              pcard = PackageCard.find_by_id(cpr.package_card_id)
              send_message = "#{customer.name}：您好，您的套餐卡#{pcard.name}".force_encoding("ASCII-8BIT").force_encoding("UTF-8")
              cpr_parm = {:content => acontent.join(","), :customer_id => customer.id}
              cpr.update_attributes(cpr_parm.merge(:status=>acount ? CPcardRelation::STATUS[:NOTIME] : CPcardRelation::STATUS[:NORMAL]))
              m_types = MessageRecord::M_TYPES[:BUY_PCARD]
              if acount
                send_message += "已经使用完."
                m_types = MessageRecord::M_TYPES[:USE_PCARD]
              else
                if selected_prods[prod_id].nil?
                  m_types = MessageRecord::M_TYPES[:USE_PCARD]
                  send_message +=  "消耗#{pname}#{selected_prods[prod_id]}次,剩余项目为："
                else
                  send_message += "包含项目为"
                end
                acontent.each do |single_card|
                  send_message += "#{single_card.split('-')[1]}#{single_card.split('-')[2]}次，"
                end
                send_message += "有效期截至#{cpr.ended_at.strftime("%Y-%m-%d")}."
              end
              #如果客户的这个套餐卡次数用光了，则将这个套餐卡关闭
              (selected_prods).each do |k, v|
                OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpr.id, :product_id => k, :product_num => v)
                product = Product.find_by_id(k)
                sale_percent = pcard.nil? ? nil :  pcard.sale_percent.round(2)
                pay_price = product.sale_price * v * sale_percent if sale_percent
                sale_price= (product.sale_price * v) - pay_price if pay_price
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:FAVOUR], :price => sale_price.to_f,
                  :product_id => k, :product_num => v)
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD], :price => pay_price.to_f,
                  :product_id => k, :product_num => v)
              end if selected_prods.length > 0
            end
          end if prods
          message_data(customer.store_id,send_message,customer,nil,m_types) if m_types #发送短信
          order.update_attributes(:is_pleased => is_pleased, :is_billing => is_billing, :is_free => pay_type==5 ? 1 : 0,
            :sale_id => sale_id.nil? || sale_id == 0 ? nil : sale_id, :c_pcard_relation_id => c_pcard_relation_id.blank? ? nil : c_pcard_relation_id.join(","),
            :c_svc_relation_id => c_svc_relation_id.blank? ? nil : c_svc_relation_id.join(","), :status => Order::STATUS[:BEEN_PAYMENT],
            :front_deduct => deduct_price, :technician_deduct => techin_price, :customer_id => customer.id)
          tech_orders =  order.tech_orders
          tech_orders.update_all(:own_deduct =>techin_price/tech_orders.length ) unless tech_orders.blank?
          if work_order  && work_order.status == WorkOrder::STAT[:WAIT_PAY]
            work_order.update_attribute("status", WorkOrder::STAT[:COMPLETE])
          end
          parms = {:customer_id=>customer.id,:car_num_id=>order.car_num_id,:phone=>customer.mobilephone,:store_id=>order.store_id,:status=>SendMessage::STATUS[:WAITING]}
          SendMessage.create(parms.merge({:content=>warns.join("\n"),:types=>SendMessage::TYPES[:WARN],:send_at=>order.warn_time}))  if order.warn_time
          SendMessage.create(parms.merge({:content=>revist.join("\n"),:types=>SendMessage::TYPES[:REVIST],:send_at=>order.auto_time}))  if order.auto_time
          customer.update_attributes(:is_vip=>Customer::IS_VIP[:VIP])  if !customer.is_vip && is_vip
        end
      else
        status = 0
        msg = "付款失败，该订单已付款！"
      end
      render :json => {:status => status, :msg => msg, :orders =>working_orders(params[:store_id])}
    end
  end

  #当pad没有权限付款时，点击确定按钮到此action
  def pay_order_no_auth
    Customer.transaction do
      customer = Customer.find_by_id(params[:customer_id].to_i)
      ocid = customer.id
      car_num = CarNum.find_by_id(params[:car_num_id].to_i)
      car_num.update_attributes(:car_model_id => params[:brand].nil? || params[:brand].split("_")[1].nil? ? nil : params[:brand].split("_")[1].to_i,
        :buy_year => params[:year], :distance => params[:cdistance].nil? ? nil : params[:cdistance].to_i)
      customer.update_attributes(:name => params[:userName].nil? ? nil : params[:userName].strip, :mobilephone => params[:phone].nil? ? nil : params[:phone].strip,
        :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i,
        :property => params[:cproperty].to_i, :group_name => params[:cproperty].to_i==0 ? nil : params[:cgroup_name])
      order = Order.find_by_id(params[:order_id].to_i)
      order.update_attribute("customer_id", customer.id)
      total_price = params[:total_price].to_f
      is_billing,status = 1,1
      is_pleased = params[:is_please].to_i
      o_status = Order::STATUS[:COMMIT]
      msg = "付款成功!"
      prods = params[:prods].split(",") #[0_255_2_200, 1_47_255=20, 2_322_0_0_16=200_128, 3_111_0_16=2_147]
      #      prods.each do |prod|
      #        if prod.split("_")[0].to_i==3
      #          arr = prod.split("_")
      #          if arr[2].to_i==1  #如果用户买了新的套餐卡，则要判断该卡需不需要消耗物料，并且该物料库存是否足够
      #            pid = arr[1].to_i
      #            pmrs = PcardMaterialRelation.find_by_sql(["select pmr.material_num mnum, m.storage storage from pcard_material_relations
      #                 pmr inner join materials m on pmr.material_id=m.id where pmr.package_card_id=?#", pid])
      #            pmrs.each do |pmr|
      #              if pmr.mnum > pmr.storage
      #                status = 0
      #                msg = "您购买的套餐卡所需的物料库存不足!"
      #                break
      #              end
      #            end if pmrs
      #          end
      #        end
      #      end
      if status==1
        c_pcard_relation_id = []
        c_svc_relation_id = []
        deduct_price = 0
        techin_price = 0
        sale_id = 0
        prods.each do |prod|  #1_47_255=20
          arr = prod.split("_")
          if prod.split("_")[0].to_i==0 #如果有产品
            product = Product.find_by_id(arr[1].to_i)
            deduct_price = deduct_price + (product.deduct_price.to_f + product.deduct_percent.to_f) * arr[2].to_i
            techin_price = techin_price + (product.techin_price.to_f + product.techin_percent.to_f) * arr[2].to_i
          elsif prod.split("_")[0].to_i==1 #如果有活动   [1,47,255=20]
            arr = prod.split("_")
            sale_id = arr[1].to_i  #[1,47,255=20]
            arr.each do |a|  #[1,47,255=20]
              if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:SALE], :price => a.split("=")[1].to_f,
                  :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
              end
            end
          elsif prod.split("_")[0].to_i==2  #如果有优惠卡 2_322_0_0_16=200_128
            sid = arr[1].to_i
            if arr[2].to_i==0 #如果是打折卡
              arr.each do |a|
                if !a.split("=")[1].nil? && !a.split("=")[2].nil?
                  OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:DISCOUNT_CARD],
                    :price => a.split("=")[1].to_f, :product_id => a.split("=")[0].to_i, :product_num => a.split("=")[2].to_i)
                end
              end
              if arr[3].to_i==0 #如果是用户已有的打折卡
                csrid = arr[-1].to_i  #用户-打折卡关联id
                c_svc_relation_id << csrid
              elsif arr[3].to_i==1  #如果是用户刚买的打折卡，则要更新客户-打折卡关系记录
                csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", ocid,
                    sid, order.id, CSvcRelation::STATUS[:invalid]]).first
                if csr.nil?
                  status = 0
                  msg = "数据错误!"
                else
                  csr.update_attributes(:customer_id => customer.id)
                  c_svc_relation_id << csr.id
                end
              end
            elsif  arr[2].to_i==1 && arr[3].to_i==1 #如果是新买的储值卡，则更新储值卡-用户关联关系
              csr = CSvcRelation.where(["customer_id=? and sv_card_id=? and order_id=? and status=?", ocid, sid,
                  order.id, CSvcRelation::STATUS[:invalid]]).first
              if csr.nil?
                status = 0
                msg = "数据错误!"
              else
                sv_card = SvCard.find(sid)
                send_message = "#{customer.name}：您好，您购买的储值卡#{sv_card.name},余额为#{csr.left_price}元，密码是#{arr[-1].strip}，请您尽快付款使用。"
                csr.update_attributes(:customer_id => customer.id, :password => Digest::MD5.hexdigest(arr[-1].strip))
                message_data(customer.store_id,send_message,customer,nil,MessageRecord::M_TYPES[:BUY_SV])
              end
            end
          elsif prod.split("_")[0].to_i==3  #如果是套餐卡
            pid = arr[1].to_i
            selected_prods = arr.inject({}){|a, s|   #[2-5,56-1]
              unless s.split("=")[1].nil?
                apid = s.split("=")[0].to_i
                apcount = s.split("=")[1].to_i
                a[apid] = apcount
              end
              a
            }
            if arr[2].to_i==0 #如果是用户已有的套餐卡,则要扣除购买的产品对应的数量
              cprid = arr[-1].to_i
              cpr = CPcardRelation.find_by_id(cprid)
              pcard = PackageCard.find_by_id(cpr.package_card_id)
              cpr_content = cpr.content.split(",") #[2-产品1-22,56-服务2-3, 17-产品2-3]
              a,yes = [],true
              send_message = "#{customer.name}：您好，您的套餐卡#{pcard.name}  "
              (cpr_content ||[]).each do |cc|
                ccid = cc.split("-")[0].to_i
                ccname = cc.split("-")[1]
                cccount = cc.split("-")[2].to_i
                if selected_prods[ccid]
                  a << "#{ccid}-#{ccname}-#{cccount - selected_prods[ccid]}"
                  yes = false if cccount > selected_prods[ccid]
                else
                  a << "#{ccid}-#{ccname}-#{cccount}"
                  yes = false if cccount >0
                end
              end
              if yes
                send_message += "已经使用完."
              else
                send_message += "剩余项目为："
                a.each do |single_card|
                  send_message += "#{single_card.split('-')[1]}#{single_card.split('-')[2]}次，"
                end
                send_message += "有效期截至#{cpr.ended_at.strftime("%Y-%m-%d")}."
              end
              message_data(customer.store_id,send_message,customer,nil,MessageRecord::M_TYPES[:USE_PCARD])
              cpr.update_attribute("content", a.join(","))
              c_pcard_relation_id << cpr.id
              o_status = Order::STATUS[:BEEN_PAYMENT]
            elsif arr[2].to_i==1  #如果是用户刚买的套餐卡，则要扣掉刚买的产品，并且生成客户-套餐卡关系
            end
          
            (selected_prods).each do |k, v|
              OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpr.id, :product_id => k, :product_num => v)
              product = Product.find_by_id(k)
              sale_percent = pcard.nil? ? nil :  pcard.sale_percent.round(2)
              pay_price = product.sale_price * v * sale_percent if sale_percent
              sale_price= (product.sale_price * v) - pay_price if pay_price
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:FAVOUR], :price => sale_price.to_f,
                :product_id => k, :product_num => v)
              OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD], :price => pay_price.to_f,
                :product_id => k, :product_num => v)
            end if selected_prods.length > 0
          end
        end if prods
        order.update_attributes(:is_pleased => is_pleased, :is_billing => is_billing, :is_free => 0,
          :sale_id => sale_id.nil? || sale_id == 0 ? nil : sale_id, :c_pcard_relation_id => c_pcard_relation_id.blank? ? nil : c_pcard_relation_id.join(","),
          :c_svc_relation_id => c_svc_relation_id.blank? ? nil : c_svc_relation_id.join(","), :status => o_status,
          :front_deduct => deduct_price, :technician_deduct => techin_price, :customer_id => customer.id)
        tech_orders =  order.tech_orders
        tech_orders.update_all(:own_deduct =>techin_price/tech_orders.length ) unless tech_orders.blank?
        work_orders = status==0 ? nil : working_orders(params[:store_id])
        render :json => {:status => status, :msg => msg, :orders => work_orders}
      end
    end
  end

  #取消订单
  def cancel_order
    Order.transaction do
      order = Order.find_by_id(params[:order_id].to_i)
      work_order = order.work_orders[0]
      cpr = CPcardRelation.find_by_status_and_order_id(CPcardRelation::STATUS[:INVALID], order.id)
      oprs = OrderProdRelation.where(["order_id=?", order.id])
      if cpr
        pmr = PcardMaterialRelation.joins(:material).where(:package_card_id=>cpr.package_card_id).
          select("sum(materials.storage,material_num) result,material_id").first
        Material.update_storage(pmr.material_id,pmr.result,order.front_staff_id,"pad销售套餐卡退卡返回物料",nil) if pmr #更新库存并生成出库记录
      elsif oprs.any?
        oprs.each do |opr|
          product = Product.find_by_id(opr.product_id)
          if !product.is_service
            pmr = ProdMatRelation.joins(:material).where(:product_id =>product.id).
              select("sum(materials.storage,material_num*pro_num) result,material_id").first
            Material.update_storage(pmr.material_id,pmr.result,order.front_staff_id,"pad销售产品退卡返回物料",nil) if pmr #更新库存并生成出库记录
          end
        end
      end
      if order.update_attributes(:status => Order::STATUS[:RETURN], :return_types => Order::IS_RETURN[:YES])
        if params[:type].to_i == 1
          work_order.arrange_station
        end
        order.work_orders.inject([]){|h,wo| wo.update_attribute("status", WorkOrder::STAT[:CANCELED])}
        work_orders = working_orders params[:store_id]
        render :json => {:status => 1, :msg => "退单成功!", :orders => work_orders}
      end
    end
  end
  
  #生成订单投诉记录
  def complaint
    complaint = Complaint.mk_record(params[:store_id],params[:order_id],params[:reason],params[:request],0)
    render :json => {:status => (complaint.nil? ? 0 : 1)}
  end
  
  #输入车牌或者电话号码查看客户的套餐卡列表
  def customer_pcards
    status = 1
    msg = ""
    num_phone = params[:num].nil? ? nil : params[:num].strip
    #phone = params[:phone].nil? ? nil : params[:phone].strip
    store_id = params[:store_id].to_i
    type = params[:type].to_i
    package_cards = []
    if type == 0
      customer = CarNum.get_customer_info_by_carnum(store_id, num_phone) if num_phone
      if customer.nil?
        status = 0
        msg = "没有找到对应的客户!"
      else
        cpcards = CPcardRelation.where(["customer_id =? and DATE_FORMAT(ended_at, '%Y%m%d') >= ? and status =?", customer.customer_id,
            Time.now.strftime("%Y%m%d"), CPcardRelation::STATUS[:NORMAL]])
        if cpcards.blank?
          status = 2
          msg = "该客户没有有效的套餐卡!"
        end
      end
    elsif type == 1
      customer = CarNum.get_customer_info_by_phone(store_id, num_phone) if num_phone
      if customer.nil?
        status = 0
        msg = "没有找到对应的客户!"
      else
        cpcards = CPcardRelation.where(["customer_id =? and DATE_FORMAT(ended_at, '%Y%m%d') >= ? and status =?", customer.customer_id,
            Time.now.strftime("%Y%m%d"), CPcardRelation::STATUS[:NORMAL]])
        if cpcards.blank?
          status = 2
          msg = "该客户没有有效的套餐卡!"
        end
      end
    end
    if status == 1 || status == 2
      if status == 1
        opr = OPcardRelation.select("ifnull(sum(product_num),0) num,c_pcard_relation_id,product_id").where(:c_pcard_relation_id => cpcards.map(&:id) ).
          group('c_pcard_relation_id,product_id').inject([]){|a,o| a << "#{o.c_pcard_relation_id}-#{o.product_id}-#{o.num}" if o.num != 0;a}
        cpcards.each do |cpcard|
          p = {}
          p_array = []
          card = PackageCard.find_by_id(cpcard.package_card_id)
          cpcard.content.split(",").each do |c|
            product = Product.find_by_id(c.split("-")[0].to_i)
            pmr = ProdMatRelation.find_by_sql(["select pmr.material_num num,m.storage from prod_mat_relations pmr left join materials m on
            pmr.material_id=m.id and m.storage>0 where pmr.product_id=?", c.split("-")[0].to_i])
            array = []
            pmr.each do |pm|
              array << pm.storage.to_i / pm.num
            end if pmr
            hash = {}
            hash[:mat_num] = array.min.nil? ? nil : array.min
            hash[:name] = product.name
            hash[:id] = product.id
            hash[:leftNum] = c.split("-")[2].to_i
            opr.each do |op|
              if op.split("-")[1].to_i == c.split("-")[0].to_i && op.split("-")[0].to_i == cpcard.id
                hash[:useNum] = op.split("-")[2].to_i
              end
            end
            hash[:selected] = 1
            p_array << hash
          end
          p[:products] = p_array
          p[:cpard_relation_id] = cpcard.id
          p[:ended_at] = cpcard.ended_at.nil? ? nil : cpcard.ended_at.strftime("%Y-%m-%d")
          p[:id] = card.id
          p[:name] = card.name
          package_cards << p
        end
      end
      user = {
        :cid => customer.customer_id,
        :cname => customer.name ,
        :cmoilephone =>customer.mobilephone,
        :cproperty => customer.property.to_i,
        :cgroup_name => customer.property.to_i==0 ? nil : customer.group_name,
        :cmodel => type == 0 ? customer.model_name : nil,
        :cbrand => type == 0 ? customer.brand_name : nil
      }
    end
    render :json => {:status => status, :msg => msg, :package_cards => package_cards, :user => user}
  end

  #通过套餐卡直接下单
  def package_make_order
    cprid = params[:c_id].to_i
    store_id = params[:store_id].to_i
    cid = params[:customer_id].to_i
    num = params[:num].nil? ? nil : params[:num].strip
    staff_id = params[:staff_id].to_i
    Order.transaction do
      customer = Customer.find cid
      cn = CarNum.find_by_num(num) if num
      msg = []
      params[:proid_and_num].split(",").each do |prod_num|
        product_id = prod_num.split("_")[0].to_i
        product_num = prod_num.split("_")[1].to_i
        create_result = OrderProdRelation.make_record(product_id, product_num, staff_id, cid, cn.id, store_id)
        status = create_result[0]
        msg << create_result[1] if create_result[1] != ""
        product = create_result[2]
        order = create_result[3]
        if status == 1
          cpcard = CPcardRelation.find_by_id(cprid)
          pcard = PackageCard.find_by_id(cpcard.package_card_id)
          array = []
          flag = true
          send_message = "#{customer.name}：您好，您购买的套餐卡:#{pcard.name}已使用#{product.name}#{product_num}次，"
          cpcard.content.split(",").each do |c|
            if c.split("-")[0].to_i == product_id
              array << "#{c.split("-")[0].to_i}-#{c.split("-")[1]}-#{c.split("-")[2].to_i - product_num}"
              flag = false if c.split("-")[2].to_i > product_num
            else
              flag = false if c.split("-")[2].to_i != 0
              array << c
            end
          end
          cpr_parm = {:content=>array.join(",")}
          cpr_parm.merge!(:status=>CPcardRelation::STATUS[:NOTIME])  if flag #如果这个套餐卡次数全用光了，则把他的status设为已用完
          if flag
            send_message += "已经使用完."
          else
            send_message += "剩余项目为："
            array.each do |single_card|
              send_message += "#{single_card.split('-')[1]}#{single_card.split('-')[2]}次，"
            end
            send_message += "有效期截至#{cpcard.ended_at.strftime("%Y-%m-%d")}."
          end
          message_data(store_id,send_message,customer,nil,MessageRecord::M_TYPES[:USE_PCARD]) #发送短信
          cpcard.update_attributes(cpr_parm)
          OPcardRelation.create(:order_id => order.id, :c_pcard_relation_id => cpcard.id, :product_id => product_id,
            :product_num => product_num)
          techin_price =  (product.techin_price.to_f + product.techin_percent.to_f) * product_num
          front_deduct = (product.deduct_percent.to_f + product.deduct_price.to_f) * product_num
          order.update_attributes(:status => Order::STATUS[:BEEN_PAYMENT],:technician_deduct =>techin_price,
            :front_deduct => front_deduct,:is_free => 0, :c_pcard_relation_id => "#{cprid}", :customer_id => cid)
          tech_orders =  order.tech_orders
          tech_orders.update_all(:own_deduct =>techin_price/tech_orders.length ) unless tech_orders.blank?
          if pcard
            pay_price = (order.price * pcard.sale_percent).round(2)
            sale_price = order.price - pay_price
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:FAVOUR], :price => sale_price.to_f,
              :product_id => product_id, :product_num =>product_num)
            OrderPayType.create(:order_id => order.id, :pay_type => OrderPayType::PAY_TYPES[:PACJAGE_CARD], :price => pay_price.to_f,
              :product_id =>product_id, :product_num =>product_num)
          end
        end
      end
      render :json => {:status => 1, :msg => msg, :orders => working_orders(store_id)}
    end
  end

  #套餐卡消费,确定付款或退单
  def pcard_make_order_commit
    type = params[:type].to_i
    status = 1
    msg = ""
    Order.transaction do
      order = Order.find_by_id(params[:order_id].to_i)
      if type ==0 #退单
        if order && (order.c_pcard_relation_id.nil? || order.c_pcard_relation_id.to_i == 0 || order.c_pcard_relation_id.split(",").length > 1)
          status = 0
          msg = "数据错误!"
        else
          order.update_attributes(:status => Order::STATUS[:RETURN], :return_types => Order::IS_RETURN[:YES])
          order.work_orders.inject([]){|h,wo| wo.update_attribute("status", WorkOrder::STAT[:CANCELED])}
          cpcard = CPcardRelation.find_by_id(order.c_pcard_relation_id.split(",")[0].to_i)
          oprs = OrderProdRelation.where(["order_id=?", order.id])
          oprs.each do |opr|
            product = Product.find_by_id(opr.product_id)
            if !product.is_service
              pmr = ProdMatRelation.joins(:material).where(:product_id =>product.id).
                select("sum(materials.storage,material_num*pro_num) result,material_id").first
              Material.update_storage(pmr.material_id,pmr.result,order.front_staff_id,"pad销售产品退卡返回物料",nil,order) if pmr #更新库存并生成出库记录
            end
          end if oprs
          array,cpr_parm =  [],{}
          opr = OrderProdRelation.find_by_order_id(order.id)  #获取该订单所包含的products，并判断该套餐卡是否有能力支付这些products
          product = Product.find_by_id(opr.product_id)
          cpcard.content.split(",").each do |c|
            if c.split("-")[0].to_i == opr.product_id
              array << "#{c.split("-")[0].to_i}-#{c.split("-")[1]}-#{c.split("-")[2].to_i+opr.pro_num}"
              cpr_parm.merge!(:status=>CPcardRelation::STATUS[:NORMAL]) if cpcard.status == CPcardRelation::STATUS[:NOTIME]
            else
              array << c
            end
          end
          cpcard.update_attributes(cpr_parm.merge(:content=>array.join(",")))
          OPcardRelation.where(:order_id => order.id, :c_pcard_relation_id => cpcard.id, :product_id => opr.product_id).delete_all
          OrderPayType.where(:order_id => order.id).delete_all
        end
      elsif type == 1 #确定---更新订单数据
        order.update_attributes(:is_pleased=>params[:is_pleased].to_i)
      end
    end
    work_orders = working_orders params[:store_id]
    render :json => {:status => status, :msg => msg, :orders => work_orders}
  end

  def update_customer
    status = 1
    begin
      Customer.transaction do
        customer = Customer.find_by_id_and_store_id(params[:customer_id].to_i,params[:store_id].to_i)
        car_num = CarNum.find_by_id(params[:car_num_id].to_i)
        car_num.update_attributes(:car_model_id => params[:brand].nil? || params[:brand].split("_")[1].nil? ? nil : params[:brand].split("_")[1].to_i,
          :buy_year => params[:year], :distance => params[:cdistance].nil? ? nil : params[:cdistance].to_i)
        customer.update_attributes(:name => params[:userName].nil? ? nil : params[:userName].strip, :mobilephone => params[:phone].nil? ? nil : params[:phone].strip,
          :birthday => params[:birth].nil? || params[:birth].strip=="" ? nil : params[:birth].strip.to_datetime, :sex => params[:sex].to_i,
          :property => params[:cproperty].to_i, :group_name => params[:cproperty].to_i==0 ? nil : params[:cgroup_name])
        status = 0
      end
    rescue
    end
    render :json => {:status => status}
  end
  

  def update_tech
    begin
      order = Order.find(params[:order_id])
      work_order = WorkOrder.where(:order_id => order.id).first
      order_stations,station_staffs = [],[]
      params[:techIDStr].split(",").each do |staff_id|
        order_stations << TechOrder.new(:staff_id=>staff_id,:order_id=>params[:order_id],:own_deduct=>order.technician_deduct/params[:techIDStr].split(",").length)
        station_staffs << StationStaffRelation.new(:station_id =>work_order.station_id,:staff_id => staff_id,:store_id => order.store_id )
      end
      TechOrder.where(:order_id=>params[:order_id]).delete_all
      TechOrder.import order_stations
      StationStaffRelation.delete_all(:store_id =>order.store_id, :station_id => work_order.station_id)
      StationStaffRelation.import station_staffs
      status = 0
    rescue
      status = 1
    end
    render :json => {:status => status}
  end
  
  def get_customer_info
    store_id = chain_store(params[:store_id])
    car_num_phone = params[:carNumOrPhone]
    status = 1
    customer = Customer.joins(:customer_num_relations=>:car_num).joins("left join car_models m on m.id=car_nums.car_model_id left join
     car_brands b on b.id=m.car_brand_id").where(:"car_nums.num"=>car_num_phone,:"customers.store_id"=>store_id).select("car_nums.id n_id,customers.id,
     customers.name c_name,mobilephone,sex,date_format(ifnull(customers.birthday,now()),'%Y-%m-%d') birth,buy_year,address,group_name,
     distance,property,num,b.name b_name,m.name m_name").where(:status=>Customer::STATUS[:NOMAL]).first
    records,uncomplete ={},{}
    if customer
      status = 0
      orders = Order.joins("left join work_orders w on w.order_id=orders.id left join complaints c on c.order_id=orders.id").
        where(:"orders.store_id"=>params[:store_id],:customer_id=>customer.id,:car_num_id=>customer.n_id).select("orders.id,
       w.station_id t_id,orders.customer_id,w.status w_status,date_format(orders.created_at,'%Y-%m-%d %H:%i') time,orders.status,c.id v_id,
      w.id w_id,orders.code,front_staff_id s_id,orders.price o_price").order("orders.created_at desc").group_by{|i|{:status=>i.status,:customer_id=>i.customer_id}}
      orders.select{|k,v|Order::PRINT_CASH.include? k[:status]}.each  {|k,v|
        records[k[:customer_id]].nil? ?  records[k[:customer_id]] = v  : records[k[:customer_id]]<< v;records[k[:customer_id]]=records[k[:customer_id]].flatten}
      orders.select{|k,v|Order::CASH.include? k[:status]}.each  {|k,v|
        uncomplete[k[:customer_id]].nil? ?  uncomplete[k[:customer_id]] = v  : uncomplete[k[:customer_id]]<< v;uncomplete[k[:customer_id]]=uncomplete[k[:customer_id]].flatten}
      tech_orders = TechOrder.where(:order_id=>orders.values.flatten.map(&:id).uniq.compact).group_by{|i|i.order_id}.inject({}){|h,k_v|h[k_v[0]]=k_v[1].map(&:staff_id);h}
      order_prod = OrderProdRelation.order_products(orders.values.flatten.map(&:id).uniq.compact)
      cards = Customer.card_infos(customer.id,store_id)
      reserv_staffs = []
      reservs = Reservation.where(:customer_id=>customer.id,:store_id=>store_id,:status=>Reservation::STATUS[:normal],:car_num_id=>customer.n_id).
        select("date_format(res_time,'%Y-%m-%d %H:%i') time,types,customer_id,staff_id,prod_types,prod_id,prod_price,prod_num,id,code").map {|reserv|
        model = reserv.prod_types < 2 ? Product : (reserv.prod_types == 2 ? PackageCard : SvCard)
        prod = model.find(reserv.prod_id)
        reserv_staffs << reserv.staff_id
        reserv[:name] = prod.name
        reserv[:price] = prod.attributes["price"]||=prod.attributes["sale_price"]
        reserv
      }.group_by{|i|i.customer_id}   #获取预订单和意向单
      staffs = Staff.where(:id=>(tech_orders.values.flatten|orders.values.flatten.map(&:s_id)|reserv_staffs).uniq.compact).inject({}){|h,s|h[s.id]=s.name;h}
      pay_types = OrderPayType.order_pay_types(records.values.flatten.map(&:id))
      pay_orders = {}
      OrderPayType.pay_order_types(records.values.flatten.map(&:id)).each {|k,types|pay_orders[k]=types.select{|k,v|OrderPayType::LOSS.include? k}.values.inject(0){|sum,n|sum+n}}
      render :json=>{:customers =>customer,:status=>status,:records=>records,:order_prods =>order_prod,:staffs=>staffs,
        :uncomplete=>uncomplete,:tech_orders=>tech_orders,:pay_types=>pay_types,:cards=>cards,:pay_orders=>pay_orders,:reservs =>reservs }
    else
      render :json=>{:status=>status}
    end

  end

end