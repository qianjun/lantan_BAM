#encoding: utf-8
class CSvcRelation < ActiveRecord::Base
  include ApplicationHelper
  has_many :svcard_use_records
  belongs_to :sv_card
  has_one :order
  belongs_to :customer

  STATUS = {:valid => 1, :invalid => 0}         #1有效的，0无效
  SEL_METHODS = {:PCARD => 2,:SV =>1,:DIS =>0 ,:BY_PCARD => 3, :BY_SV => 4,:PROD =>6,:SERV =>5}
  #1 购买储值卡 0  购买打折卡 2 购买套餐卡 3 通过套餐卡购买 4 通过打折卡购买 5 购买服务 6 购买产品
  SEL_PROD = [SEL_METHODS[:BY_PCARD],SEL_METHODS[:BY_SV],SEL_METHODS[:PROD],SEL_METHODS[:SERV]]
  SEL_SV = [SEL_METHODS[:SV],SEL_METHODS[:DIS]]

  #获取用户的已购买的所有打折卡
  def self.get_customer_discount_cards  customer_id, store_id
    sc = CSvcRelation.find_by_sql(["select sv.id sid, sv.name sname, sv.types stype, sv.price sprice, csr.id csrid from c_svc_relations csr inner join
          sv_cards sv on sv.id=csr.sv_card_id where csr.customer_id=? and csr.status=? and ((sv.store_id=? and sv.use_range=?)or(sv.store_id in (?) and
          sv.use_range=?)) and sv.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:DISCOUNT]]).uniq
    sv_cards = sc.inject([]){|h,s|
      a = {}
      a[:csrid] = s.csrid
      a[:svid] = s.sid
      a[:svname] = s.sname
      a[:svprice] = s.sprice
      a[:svtype] = s.stype
      a[:is_new] = 0
      a[:show_price] = 0
      a[:products] = []
      items = SvcardProdRelation.find_by_sql(["select spr.product_discount, p.name, p.id, p.sale_price from svcard_prod_relations spr
            inner join products p on spr.product_id=p.id where spr.sv_card_id=?", s.sid])
      items.each do |i|
        hash = {}
        hash[:pid] = i.id
        hash[:pname] = i.name
        hash[:pprice] = i.sale_price
        hash[:pdiscount] = i.product_discount.to_i*0.1
        hash[:selected] = 1
        a[:products] << hash
      end
      h << a;
      h
    }
    sv_cards
  end

  #获取该用户所有支持某个产品付款的储值卡
  def self.get_customer_supposed_save_cards  customer_id, store_id, p_id
    result = []
    sc = CSvcRelation.find_by_sql(["select csr.id csrid, csr.left_price l_price, sc.id sid, sc.name sname
       from c_svc_relations csr inner join sv_cards sc on csr.sv_card_id=sc.id
      where csr.customer_id=? and csr.status=? and ((sc.store_id=? and sc.use_range=?)or(sc.store_id in (?) and
      sc.use_range=?)) and sc.types=?", customer_id, CSvcRelation::STATUS[:valid], store_id, SvCard::USE_RANGE[:LOCAL],
        StoreChainsRelation.return_chain_stores(store_id), SvCard::USE_RANGE[:CHAINS], SvCard::FAVOR[:SAVE]]).uniq
    category_id = Product.find_by_id(p_id).category_id.to_i
    sc.each do |s|
      spr = SvcardProdRelation.find_by_sv_card_id(s.sid)
      if spr.category_id && spr.category_id.split(",").inject([]){|h, c| h << c.to_i;h }.include?(category_id)
        h = {}
        h[:csrid] = s.csrid
        h[:l_price] = s.l_price
        h[:svid] = s.sid
        h[:svname] = s.sname
        result << h
      end
    end
    return result
  end


  def self.search_card(customer_id,store_id)
    suit_cards,prods,pcard = [],[],[]
    cps = CPcardRelation.find_by_sql("select p.name,c.id c_id,c.content from c_pcard_relations c inner join package_cards p
      on c.package_card_id=p.id where customer_id=#{customer_id} and c.status=#{CPcardRelation::STATUS[:NORMAL]} and
      p.store_id = #{store_id} and date_format(c.ended_at,'%Y-%m-%d') >= '#{Time.now.strftime('%Y-%m-%d')}'")
    cps.each do |cp|
      if cp.content
        cp.content.split(",").each do |p|
          content = p.split("-")
          if content[2].to_i >0
            prods << content[0].to_i
          end
        end
      end
    end unless cps.blank?
    prod = Product.where(:id=>prods.flatten.compact.uniq).inject({}){|h,p|h[p.id]=p.sale_price.nil? ? 0 : p.sale_price ;h}
    total_prms = ProdMatRelation.joins([:material,:product]).where(:product_id=>prods,:"products.is_service"=>Product::PROD_TYPES[:PRODUCT]).select("ifnull(FLOOR(materials.storage/material_num),0) num,product_id,material_id").group_by{|i|i.product_id}
    cps.each do |cp|
      is_null,con = false,[]
      cp.content.split(",").each do |p|
        content = p.split("-")
        if content[2].to_i >0
          if total_prms[content[0].to_i]
            available_num = []
            available = true
            total_prms[content[0].to_i].each do |prm|
              if prm.num <= 0
                available = false
                break
              end
              available_num << prm.num
            end
            if available
              is_null = true
              content[2] =  available_num.min if content[2].to_i > available_num.min
              con << content
            end
          elsif prod[content[0].to_i]
            is_null = true
            con << content
          end
        end
      end  if cp.content
      if is_null
        pcard << {:name =>cp.name,:content =>con,:c_id =>cp.c_id,:types =>3,:type_name =>"套餐卡"}
      end
    end unless cps.blank?
    cr_ids = CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid],:customer_id=>customer_id).map(&:sv_card_id)
    unless cr_ids.blank?
      sv_names = SvCard.where(:id=>cr_ids,:types=>SvCard::FAVOR[:DISCOUNT],:store_id=>store_id).inject({}){|h,s|h[s.id]=s.name;h}
      sv_prod = SvcardProdRelation.joins(:product).where(:sv_card_id=>sv_names.keys).select("sv_card_id,product_id,product_discount,products.name,products.is_service").inject({}){|h,s|
        h[s.sv_card_id].nil? ? h[s.sv_card_id]={s.product_id=>[s.product_discount,s.name,s.is_service]} :h[s.sv_card_id][s.product_id]=[s.product_discount,s.name,s.is_service];h}
      sv_prod_ids = sv_prod.values.inject([]){|arr,h_s| arr << h_s.keys}
      prod.merge!(Product.find((sv_prod_ids).flatten.compact.uniq).inject({}){|h,p|h[p.id]=p.sale_price;h})
      total_prms = ProdMatRelation.joins([:material,:product]).where(:product_id=>prods,:"products.is_service"=>Product::PROD_TYPES[:PRODUCT]).select("ifnull(FLOOR(materials.storage/material_num),0) num,product_id,material_id").group_by{|i|i.product_id}
      sv_names.each do |k,v| #筛选掉打折卡里面没有库存的产品或者服务
        suit_sv = {}
        sv_prod[k].each do |p,sv|
          if sv[2] == Product::PROD_TYPES[:SERVICE]
            suit_sv[p] = sv << 999
          else
            if total_prms[p]
              available_num = []
              available = true
              total_prms[p].each do |prm|
                if prm.num <= 0
                  available = false
                  break
                end
                available_num << prm.num
              end
              suit_sv[p] = sv << available_num.min    if available
            end
          end
        end
        unless suit_sv.empty?
          suit_cards << {:name =>v,:c_id =>k,:content =>suit_sv,:types =>4,:type_name =>"打折卡"}
        end
      end unless sv_names.empty?
    end
    [suit_cards,prod,pcard]
  end

  def self.set_string(len,str)
    return "0"*(len-"#{str}".length)+"#{str}"
  end

  


end
