#encoding: utf-8
class CPcardRelation < ActiveRecord::Base
  belongs_to :package_card
  belongs_to :customer
  has_one :order
  #  has_many :orders
  STATUS = {:INVALID => 0,:NORMAL => 1,:NOTIME =>2} #0 为无效 1 为正常卡 2 为过期/使用完
  STATUS_NAME = {2 => "过期/使用完", 1 => "正常使用",0=>"无效"}

  def get_content ids    
    current_prods_hash = {}
    (ids || []).each do |p_id|
      id = p_id.split("=")[0]
      num = p_id.split("=")[1]
      current_prods_hash[id] = num
    end
    prods = self.content.split(",")
    new_oroducts = []
    (prods || []).each do |prod|
      if current_prods_hash[prod.split("-")[0].to_i]
        new_oroducts << prod.split("-")[0].to_s + "-" + prod.split("-")[1].to_s + "-" + current_prods_hash[prod.split("-")[0].to_i].to_s
      else
        new_oroducts << prod
      end
    end
    new_oroducts.join(",")
    
  end

  def get_prod_num p_id
    prods = self.content.split(",")
    num = 0
    (prods || []).each do |prod|
      if prod.split("-")[0].to_i == p_id
        num = prod.split("-")[2].to_s
      end
    end
    num
  end

  def self.set_content pcard_id
    pcard_prod_relations = PcardProdRelation.find_all_by_package_card_id pcard_id
    content = nil
    content = pcard_prod_relations.collect{|r|
      s = ""
      if r.product
        s += r.product_id.to_s + "-" + r.product.name + "-" + r.product_num.to_s
      end
      s
    }.join(",") if pcard_prod_relations
    content
  end

  #删除已过期的或者已经使用完毕的客户-套餐卡记录
  def self.delete_terminate_cards 
    cards = self.where(["status = ?", self::STATUS[:NORMAL]])
    current_time = Time.now.strftime("%Y%m%d").to_i
    cards.each do |card|
      if card.content && !card.content.empty? && card.ended_at
        remain = card.content.split(",")
        a = 0
        remain.each do |r|
          count = r.split("-")[2].to_i
          a += count
        end
        if a == 0 || card.ended_at.strftime("%Y%m%d").to_i < current_time
          card.update_attribute("status", self::STATUS[:NOTIME])
        end
      else
        card.update_attribute("status", self::STATUS[:NOTIME])
      end
    end
  end

  #该用户已经所购买的套餐卡及其所支持的产品或服务
  def self.get_customer_package_cards customer_id, store_id,p_id
    pc = CPcardRelation.find_by_sql(["select cpr.content,cpr.id cprid, p.id pid, p.name pname, p.price pprice from c_pcard_relations cpr
          inner join package_cards p on cpr.package_card_id=p.id where NOW()<=cpr.ended_at and cpr.customer_id=?
          and cpr.status=? and p.status=? and p.store_id=?", customer_id, CPcardRelation::STATUS[:NORMAL],
        PackageCard::STAT[:NORMAL], store_id])
    p_cards = pc.inject([]){|a, p|
      items = p.content.split(",")    #447-0927mat1-2,448-0927mat2-2
      flag = false
      items.each do |i|           #i=447-0927mat1-2
        if i.split("-")[2].to_i > 0 && i.split("-")[0].to_i == p_id
          flag = true
          break
        end
      end if items
      if flag
        ha = {}
        ha[:cprid] = p.cprid
        ha[:pid] = p.pid
        ha[:pname] = p.pname
        ha[:pprice] = p.pprice
        ha[:ptype] = 2
        ha[:is_new] = 0
        ha[:show_price] = 0
        ha[:status] = 0
        ha[:products] = []     
        items.each do |i|           #i=447-0927mat1-2
          if i.split("-")[0].to_i == p_id
            flag = true
          end
          hash = {}
          hash[:proid] = i.split("-")[0]
          hash[:proname] = i.split("-")[1]
          hash[:pro_left_count] = i.split("-")[2]
          hash[:selected] = 1
          pprod = Product.find_by_id(i.split("-")[0].to_i)
          hash[:pprice] = pprod.nil? ? nil : pprod.sale_price
          ha[:products] << hash
        end if items
        a << ha
      end;
      a
    }
    p_cards
  end

end
