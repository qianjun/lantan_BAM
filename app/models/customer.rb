#encoding: utf-8
class Customer < ActiveRecord::Base
  has_many :customer_num_relations
  has_many :c_svc_relations
  has_many :c_pcard_relations
  has_many :revisits
  has_many :send_messages
  has_many :c_svc_relations
  has_many :reservations
  has_many :orders
  belongs_to :store
  attr_accessor :password
  validates :password, :allow_nil => true, :length =>{:within=>6..20, :message => "密码长度必须在6-20位之间"}

  #客户状态
  STATUS = {:NOMAL => 0, :DELETED => 1} #0 正常  1 删除
  #客户类型
  IS_VIP = {:NORMAL => 0, :VIP => 1,:SUP_VIP => 2} #0 常态客户 1 会员卡客户
  TYPES = {:GOOD => 0, :NORMAL => 1, :STRESS => 2} #1 优质客户  2 一般客户  3 重点客户
  C_TYPES = {0 => "优质客户", 1 => "一般客户", 2 => "重点客户"}
  RETURN_REASON = { 0 => "质量问题", 1 => "服务态度", 2 => "拍错买错",3 => "效果不好，不喜欢",4 => "操作失误", 5 => "其他"}
  PROPERTY = {:PERSONAL => 0, :GROUP => 1}  #客户属性 0个人 1集团客户
  ALLOWED_DEBTS = {:NO => 0, :YES => 1}   #是否允许欠账
  CHECK_TYPE = {:MONTH => 0, :WEEK => 1}  #结算类型 按月/周结算
  
  TAB_LIST = {1=>"单位客户",0=>"个人客户",2=>"套餐卡客户",3=>"储值卡客户",4=>"VIP客户"}
  LIST_NAME = {:GROUP =>1,:PERSONAL =>0,:PCARD =>2,:SV_CARD =>3,:VIP =>4}

  
  #加载客户的手机号和姓名
  def self.load_customers(ids)
    Customer.where(:id=>ids).select("id,name,mobilephone").inject({}){|h,c|h[c.id]=c;h}
  end

  def self.search_customer(car_num, started_at, ended_at, name, phone,  store_id)
    base_sql = "select cu.* from customers cu left join customer_num_relations cnr on
     cnr.customer_id = cu.id left join car_nums ca on ca.id = cnr.car_num_id "
    condition_sql = "where cu.status = #{STATUS[:NOMAL]} and cu.store_id = #{store_id} "
    params_arr = [""]
    unless name.nil? or name.strip.empty?
      condition_sql += " and cu.name like ? "
      params_arr << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    unless phone.nil? or phone.strip.empty?
      condition_sql += " and cu.mobilephone = ? "
      params_arr << phone.strip
    end
    unless car_num.nil? or car_num.strip.empty?
      condition_sql += " and ca.num like ? "
      params_arr << "%#{car_num.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    is_has_order = false
    unless started_at.nil? or started_at.strip.empty?
      is_has_order = true
      base_sql += " left join orders o on o.car_num_id = ca.id "
      condition_sql += " and o.created_at >= ? "
      params_arr << started_at.strip
    end
    unless ended_at.nil? or ended_at.strip.empty?
      base_sql += " left join orders o on o.car_num_id = ca.id " unless is_has_order
      condition_sql += " and o.created_at <= ?"
      params_arr << ended_at.strip.to_date + 1.days
    end
    condition_sql += " group by cu.id "
    params_arr[0] = base_sql + condition_sql
    params_arr[0] += " order by cu.created_at desc"
    return Customer.find_by_sql(params_arr)
  end

  def self.auto_generate_customer_type
    stress_customer_ids = []
    Complaint.where("created_at >= '#{Time.now.years_ago(1)}'").each do |complaint|
      customer = complaint.customer
      stress_customer_ids << customer.id and customer.update_attribute(:types, Customer::TYPES[:STRESS]) if customer && !customer.status
    end

    orders = Order.includes(:car_num => {:customer_num_relation => :customer}).
      where("orders.created_at >= '#{Time.now.years_ago(1)}'").
      where("orders.status = #{Order::STATUS[:BEEN_PAYMENT]} || orders.status = #{Order::STATUS[:FINISHED]}").
      where("customers.id not in (?)", stress_customer_ids).
      group_by{|s|s.car_num.customer_num_relation.customer.id}

    result = {}
    orders.each do |key, value|
      result[key] = value.length
    end

    Customer.where("status = #{STATUS[:NOMAL]} and id not in (?)", stress_customer_ids).each do |customer|
      if result.keys.include?(customer.id)
        types = result[customer.id] >= 12 ? Customer::TYPES[:GOOD] : Customer::TYPES[:NORMAL]
        customer.update_attribute(:types, types)
      else
        customer.update_attribute(:types, Customer::TYPES[:NORMAL])
      end
    end
  end

  def Customer.create_single_cus(customer, carnum, phone, car_num, user_name, other_way,
      birth, buy_year, car_model_id, sex, address, is_vip, store_id)
    Customer.transaction do
      if customer.nil?
        customer = Customer.create(:name => user_name, :mobilephone => phone,
          :other_way => other_way, :birthday => birth, :status => Customer::STATUS[:NOMAL],
          :types => Customer::TYPES[:NORMAL], :username => user_name,
          :password => phone, :sex => sex, :address => address,:is_vip=>is_vip,:store_id=>store_id)
        customer.encrypt_password
        customer.save        
      end
      if carnum
        carnum.update_attributes(:buy_year => buy_year, :car_model_id => car_model_id)
      else
        carnum = CarNum.create(:num => car_num, :buy_year => buy_year,
          :car_model_id => car_model_id)
      end
      CustomerNumRelation.delete_all(["car_num_id = ?", carnum.id])
      CustomerNumRelation.create(:car_num_id => carnum.id, :customer_id => customer.id)
    end 
    return [customer, carnum]
  end

  def Customer.customer_car_num(customer_ids)
    car_nums = CarNum.find_by_sql(["select cn.num, cnr.customer_id from car_nums cn
      inner join customer_num_relations cnr on cnr.car_num_id = cn.id where cnr.customer_id in (?)", customer_ids])
    return car_nums.blank? ? {} : car_nums.group_by { |i| i.customer_id }
  end

  def has_password?(submitted_password)
		encrypted_password == encrypt(submitted_password)
	end

  def encrypt_password
    self.encrypted_password=encrypt(password)
  end

  #客户使用套餐卡记录，门店后台跟api共用
  def pc_card_records_method(store_id)
    #套餐卡记录
    c_pcard_relations_no_paginate = CPcardRelation.find_by_sql(["select cpr.id  , p.id, p.name, cpr.content, cpr.ended_at
        from c_pcard_relations cpr
        inner join package_cards p on p.id = cpr.package_card_id
        where cpr.status = ? and cpr.customer_id = ? and p.store_id = ?",
        CPcardRelation::STATUS[:NORMAL], self.id, store_id])
    #    c_pcard_relations = c_pcard_relations_no_paginate.paginate(:page => page || 1, :per_page => Constant::PER_PAGE) if page
    already_used_count = {}
    if c_pcard_relations_no_paginate.present?
      c_pcard_relations_no_paginate.each do |r|
        ppr = PcardProdRelation.joins(:package_card).find(:first, :conditions => ["package_card_id = ? and package_cards.store_id = ?", r.id, store_id])
        service_infos = r.content.split(",")
        single_car_content = {}
        service_infos.each do |s|
          content_arr = s.split("-")
          single_car_content[content_arr[0].to_i] = [content_arr[1], content_arr[2].to_i] if content_arr.length == 3
        end
        already_used_count[r.cpr_id] = single_car_content unless single_car_content.empty?
        used_count = ppr.product_num - already_used_count[r.cpr_id][ppr.product_id][1] if !already_used_count.empty? and already_used_count[r.cpr_id].present? and already_used_count[r.cpr_id][ppr.product_id]
        already_used_count[r.cpr_id][ppr.product_id][1] = used_count ? used_count : 0 unless already_used_count.empty? or already_used_count[r.cpr_id].blank? or already_used_count[r.cpr_id][ppr.product_id].nil? 
      end

      [already_used_count, c_pcard_relations_no_paginate]
    else
      [{}, []]
    end
  end


  def get_discount_cards(svcard_arr)
    discont_card = CSvcRelation.find(:all, :select => "c_svc_relations.*",
      :conditions => ["c_svc_relations.customer_id = ? and c_svc_relations.status = ? and s.types= ?", self.id, CSvcRelation::STATUS[:valid], SvCard::FAVOR[:DISCOUNT]],
      :joins => ["inner join sv_cards s on s.id = c_svc_relations.sv_card_id"])
    if discont_card.any?
      discont_card.each{|r|
        s = Hash.new
        s[:scard_id] = r.sv_card_id
        s[:scard_name] = r.sv_card.name
        s[:scard_discount] = r.sv_card.discount
        s[:price] = 0
        s[:selected] = 1
        s[:show_price] = 0.0#"-" + s[:price].to_s
        s[:card_type] = 0
        s[:is_new] = 0 #表示旧的储值卡
        svcard_arr << s
        #total -= s[:price]
      }
    end
    return svcard_arr
  end

  #客户使用套餐卡记录
  def pcard_records(store_id)
    #当前客户的套餐卡
    c_pcards  = CPcardRelation.joins(:package_card).select("c_pcard_relations.id c_id,package_cards.id k_id,package_cards.name,
    c_pcard_relations.content, c_pcard_relations.ended_at,c_pcard_relations.order_id o_id").where(:"c_pcard_relations.status"=>CPcardRelation::STATUS[:NORMAL],
      :customer_id=>self.id,:"package_cards.store_id"=>store_id)
    already_used_count = {}
    p_pcards = PcardProdRelation.joins(:package_card).select("package_cards.id p_id,product_id,product_num").
      where(:"package_cards.store_id" =>store_id).inject({}){|hash,i|
      hash[i.p_id].nil? ? hash[i.p_id]={i.product_id=>i.product_num} : hash[i.p_id][i.product_id]=i.product_num;hash}
    if c_pcards.present?
      c_pcards.each do |r|
        service_infos = r.content.split(",")
        single_car_content = {}
        service_infos.each do |s|
          content_arr = s.split("-")
          if content_arr.length == 3 && p_pcards[r.k_id][content_arr[0].to_i].to_i > content_arr[2].to_i
            single_car_content[content_arr[0].to_i] = [content_arr[1],p_pcards[r.k_id][content_arr[0].to_i]-content_arr[2].to_i]
          end
        end
        already_used_count[r.c_id] = single_car_content unless single_car_content.empty?
      end
      [already_used_count, c_pcards]
    else
      [{}, []]
    end
  end


  def self.card_infos(customer_ids,store_id)
    prods,pcard,save_card,discount_card = [],{},{},{}
    cps = CPcardRelation.joins(:package_card).where(:"package_cards.store_id"=>store_id,:"c_pcard_relations.status"=>CPcardRelation::STATUS[:NORMAL],
      :customer_id=>customer_ids).select("customer_id,name,c_pcard_relations.id c_id,content,package_cards.id p_id,package_cards.name p_name,
    date_format(c_pcard_relations.ended_at,'%Y-%m-%d %H:%i:%S') time").where("date_format(c_pcard_relations.ended_at,'%Y-%m-%d') >= '#{Time.now.strftime('%Y-%m-%d')}'").group_by{|i|i.customer_id}
    cps.values.flatten.each do |cp|
      if cp.content
        cp.content.split(",").each do |p|
          content = p.split("-")
          if content[2].to_i >0
            prods << content[0].to_i
          end
        end
      end
    end unless cps.values.flatten.blank?
    total_prms = ProdMatRelation.joins([:material,:product]).where(:product_id=>prods,:"products.is_service"=>Product::PROD_TYPES[:PRODUCT]).
      select("materials.storage-material_num num,product_id,material_id").inject({}){|h,p|h[p.product_id]=p.num;h}
    pcard_prod = PcardProdRelation.where(:package_card_id=>cps.values.flatten.map(&:p_id)).inject({}){|h,p|h["#{p.product_id}_#{p.package_card_id}"]=p.product_num;h}
    cps.each.each do |customer_id,cprs|
      pcard[customer_id] = []
      cprs.each do |cp|
        cons = []
        cp.content.split(",").each do |p|
          is_abled = false
          content = p.split("-")
          if content[2].to_i >0
            if total_prms[content[0].to_i].nil?
              is_abled = true
            elsif  total_prms[content[0].to_i] >=0
              is_abled = true
            end
          end
          cons << {:name =>content[1],:total_num=>pcard_prod["#{content[0].to_i}_#{cp.p_id}"],:left_num=>content[2].to_i,:status=>is_abled,:prod_id=>content[0].to_i}
        end if cp.content
        pcard[customer_id] << {:content=>cons,:card_name=>cp.p_name,:end_time=>cp.time,:c_id=>cp.c_id}
      end  unless cprs.blank?
    end unless cps.blank?
    sv_cards = CSvcRelation.joins(:sv_card).select("c_svc_relations.*,sv_cards.name,sv_cards.description intro,sv_cards.types").
      where(:status=>CSvcRelation::STATUS[:valid],:customer_id=>customer_ids).group_by{|i|{:customer_id=>i.customer_id,:types=>i.types}}
    svcard_use_records = SvcardUseRecord.where(:c_svc_relation_id=>sv_cards.select{|k,v|k[:types] == SvCard::FAVOR[:SAVE]}.values.flatten.map(&:id)).group_by{|i|i.c_svc_relation_id}
    sv_cards.each do |k,v|
      v.each do |card|
        if k[:types] == SvCard::FAVOR[:DISCOUNT]
          if discount_card[k[:customer_id]].nil?
            discount_card[k[:customer_id]]=[{:name=>card.name,:intro=>card.intro,:time=>card.created_at.strftime("%Y-%m-%d %H:%M:%S")}]
          else
            discount_card[k[:customer_id]] << {:name=>card.name,:intro=>card.intro,:time=>card.created_at.strftime("%Y-%m-%d %H:%M:%S")}
          end
        elsif k[:types] == SvCard::FAVOR[:SAVE]
          records = []
          svcard_use_records[card.id].each do |record|
            records << {:use_price=>record.use_price,:left_price=>record.left_price,:time=>record.created_at.strftime("%Y-%m-%d"),:content=>record.content,:types=>record.types}
          end if svcard_use_records[card.id]
          if save_card[k[:customer_id]].nil?
            save_card[k[:customer_id]]=[{:name=>card.name,:time=>card.created_at.strftime("%Y-%m-%d %H:%M:%S"),:total_price=>card.total_price,:id_card=>card.id_card,:contents=>records}]
          else
            save_card[k[:customer_id]] << {:name=>card.name,:time=>card.created_at.strftime("%Y-%m-%d %H:%M:%S"),:total_price=>card.total_price,:id_card=>card.id_card,:contents=>records}
          end
        end
      end
    end
    {:pcard=>pcard,:save_card=>save_card,:discount_card=>discount_card}
  end

  
  private
  def encrypt(string)
    self.salt = make_salt if new_record?
    secure_hash("#{salt}--#{string}")
  end

  def make_salt
    secure_hash("#{Time.new.utc}--#{password}")
  end

  def secure_hash(string)
    Digest::SHA2.hexdigest(string)
  end

end
