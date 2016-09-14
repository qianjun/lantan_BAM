module MarketManagesHelper
  def prod_gross_price(order_id, oprr,order_pay_types)
    total_price = oprr.total_price.to_f  #每项商品总价

    #计算套餐卡优惠总价
   opt_pcard = order_pay_types[order_id].select{|opt| opt.product_id == oprr.product_id and opt.pay_type == OrderPayType::PAY_TYPES[:PACJAGE_CARD]}.first unless order_pay_types[order_id].blank?
    if !opt_pcard.blank?
      deals_price = opt_pcard.price
      prod_full_price_num = oprr.pro_num.to_i - opt_pcard.product_num.to_i #未使用套餐卡抵付的商品数目
      prod_cost_price = prod_full_price_num *(oprr.t_price.to_f) #未使用套餐卡抵付的商品成本价
    else
      prod_cost_price = oprr.pro_num.to_i * oprr.t_price.to_f
    end

    # 使用活动优惠总价
    opt_sale = order_pay_types[order_id].select{|opt| opt.product_id == oprr.product_id and opt.pay_type == OrderPayType::PAY_TYPES[:SALE]}.first unless order_pay_types[order_id].blank?
    unless opt_sale.blank?
      sale_price = opt_sale.price
    end

    # 使用打折卡优惠总价
    opt_sav = order_pay_types[order_id].select{|opt| opt.product_id == oprr.product_id and opt.pay_type == OrderPayType::PAY_TYPES[:DISCOUNT_CARD]}.first  unless order_pay_types[order_id].blank?
    unless opt_sav.blank?
      sav_price = opt_sav.price
    end

    ssale_price = total_price - deals_price.to_f - sale_price.to_f - sav_price.to_f  #零售价

    gross_profit = ssale_price - prod_cost_price.to_f #一个商品的毛利

    return [prod_cost_price.to_f, ssale_price,gross_profit]
  end

  def order_cost_price(order)
    #购买套餐卡里面的商品与服务成本价
    unless order.c_pcard_relations.blank?
      pp_price = order.c_pcard_relations.map{|cpr| cpr.package_card}.compact.map{|pc| pc.pcard_material_relations.map{|ppr| [ppr.material, ppr.material_num]}.inject(0){|sum,opr| sum += opr[0].try(:price).to_f * opr[1]}}.inject(0){|sum,pc| sum += pc}
    end
    #跟order直接关联的商品与服务的价钱
    sum = order.order_prod_relations.inject(0){|sum,opr| sum+=(opr.t_price.to_f)*opr.pro_num}
    order_cost_price = sum + pp_price.to_f
    order_cost_price
  end
end
