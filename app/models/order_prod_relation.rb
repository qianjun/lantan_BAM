#encoding: utf-8
class OrderProdRelation < ActiveRecord::Base
  belongs_to :order
  belongs_to :product
  
  def self.order_products(orders)
    products = OrderProdRelation.find_by_sql(["select opr.order_id, opr.pro_num, opr.price, opr.return_types,p.name,is_service,p.id p_id,
    case is_service when 0 then '产品' else '服务' end p_types,0 s_types,case is_service when 0 then '0' else '1' end item_types
    from order_prod_relations opr inner join products p on p.id = opr.product_id where opr.order_id in (?)", orders])
    @product_hash = {}
    products.each { |p|
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if products.any?
    pcar_relations = CPcardRelation.find_by_sql(["select cpr.order_id, 1 pro_num, pc.price, pc.name,return_types,
    '套餐卡' p_types,0 s_types,2 item_types from c_pcard_relations cpr inner join package_cards pc on pc.id = cpr.package_card_id where
    cpr.order_id in (?)", orders])
    pcar_relations.each { |p|
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if pcar_relations.any?
    csvc_relations = CSvcRelation.find_by_sql(["select csr.order_id, 1 pro_num, sc.price, sc.name,return_types,sc.types s_types,
    case sc.types when 0 then '打折卡' else '储值卡' end p_types,case sc.types when 0 then 3 else 4 end item_types from c_svc_relations csr inner join sv_cards sc on sc.id = csr.sv_card_id where csr.order_id in (?)", orders])
    csvc_relations.each { |p|
      @product_hash[p.order_id].nil? ? @product_hash[p.order_id] = [p] : @product_hash[p.order_id] << p
    } if csvc_relations.any?
    return @product_hash
  end

  def self.s_order_products(order_id)
    products = OrderProdRelation.find_by_sql("select opr.order_id, opr.pro_num, opr.price, p.name,is_service,p.id
        from order_prod_relations opr left join products p on p.id = opr.product_id where opr.order_id = #{order_id}")
    @product_hash = {}
    products.each { |p|
      name = p.is_service== Product::PROD_TYPES[:PRODUCT] ?  "order_prod_relation#product" :  "order_prod_relation#service"
      @product_hash[name].nil? ? @product_hash[name] = [p] : @product_hash[name] << p
    } if products.any?
    pcar_relations = CPcardRelation.find_by_sql("select cpr.order_id, 1 pro_num, pc.price, pc.name,pc.id
        from c_pcard_relations cpr inner join package_cards pc
        on pc.id = cpr.package_card_id where cpr.order_id=#{order_id}")
    pcar_relations.each { |p|
      @product_hash["c_pcard_relation#package_card"].nil? ? @product_hash["c_pcard_relation#package_card"] = [p] : @product_hash["c_pcard_relation#package_card"] << p
    } if pcar_relations.any?
    csvc_relations = CSvcRelation.find_by_sql("select csr.order_id, 1 pro_num, sc.price, sc.name,sc.id
        from c_svc_relations csr inner join sv_cards sc
        on sc.id = csr.sv_card_id where csr.order_id = #{order_id}")
    csvc_relations.each { |p|
      @product_hash["c_svc_relation#sv_card"].nil? ? @product_hash["c_svc_relation#sv_card"] = [p] : @product_hash["c_svc_relation#sv_card"] << p
    } if csvc_relations.any?

    return @product_hash
  end

  #pad上点击确认下单之后，生产一条订单记录及其与prodcuts关联的记录
  def self.make_record p_id, p_num, staff_id, cus_id, car_num_id, store_id,purpose_price=nil
    Order.transaction do
      product = Product.find_by_id(p_id)
      status = 1
      msg = ""
      if product
        unless product.is_service
          pmr = ProdMatRelation.find_by_product_id(product.id)
          m = Material.find_by_id(pmr.material_id) if pmr
          if m && m.storage < p_num * pmr.material_num
            status =0
            msg = "#{product.name}所需的物料#{m.name}库存不足!"
          end
        end
        if status == 1 && (product.is_service || product.is_added)
          check_station = Station.arrange_time(store_id, [p_id])
          case check_station[1]
          when  0
            status =0
            msg = "#{product.name}无合适的工位!"
          when 2
            status = 0
            msg = "需要使用多个工位，请分别下单!"
          when 3
            status = 0
            msg = "服务所需的工位没有技师!"
          end
        end
        if status == 1
          order_parm = {
            :code => MaterialOrder.material_order_code(store_id),
            :car_num_id => car_num_id,:status => Order::STATUS[:WAIT_PAYMENT],:store_id => store_id,
            :price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : purpose_price.nil? ? product.sale_price.to_f*p_num : purpose_price.to_f*p_num,
            :is_billing => false,:front_staff_id =>staff_id,:customer_id => cus_id,:is_visited => Order::IS_VISITED[:NO],
            :types => Order::TYPES[:SERVICE],:auto_time => product.is_auto_revist ? Time.now + product.auto_time.to_i.hours : nil}
          order = Order.create(order_parm)
          relation_parm = {:order_id => order.id,:product_id => p_id,:pro_num => p_num,
            :price => product.single_types == Product::SINGLE_TYPE[:DOUB] ?  0 : purpose_price.nil? ? product.sale_price : purpose_price,
            :total_price => product.single_types == Product::SINGLE_TYPE[:DOUB] ? 0 : purpose_price.nil? ? product.sale_price.to_f*p_num : purpose_price.to_f*p_num,
            :t_price => product.single_types == Product::SINGLE_TYPE[:DOUB] ?  0 : product.t_price.to_f*p_num}
          OrderProdRelation.create(relation_parm)
          Material.update_storage(m.id,m.storage - p_num * pmr.material_num,staff_id,"销售产品出库",nil,order) unless product.is_service #更新库存并生成出库记录
          if product.is_service || product.is_added
            arrange_time = Station.arrange_time(store_id,[p_id],order)
            hash = Station.create_work_order(arrange_time, order, product.cost_time.to_i*p_num)
            order.update_attributes(hash)
          end
        end
      end
      return [status, msg, product, order]
    end
  end

end
