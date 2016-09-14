#encoding: utf-8
namespace :monthly do
  desc "generate chart from google_chart by diffent types of complaint"
  task(:operate_charts => :environment) do
    Store.all.each {|store| Complaint.gchart(store.id)}
  end
  
  task(:operate_satify => :environment) do
    Store.all.each {|store| Complaint.degree_chart(store.id)}
  end


  desc "generate front and technician average chart image"
  task(:generate_avg_chart_image => :environment) do
    ChartImage.generate_avg_chart_image
  end

  desc "generate staff score chart image"
  task(:generate_staff_score_chart_image => :environment) do
    ChartImage.generate_staff_score_chart
  end
end


#2.3新版初始化执行程序
task(:change_types => :environment) do
  Store.where(:status=>Store::STATUS[:OPENED]).each do |store|
    #需要先把预存数据加进去
    Material::TYPES_NAMES.values.each do |mat_name|
      Category.create(:name => mat_name, :types =>Category::TYPES[:material], :store_id => store.id)
    end
    Product::PRODUCT_TYPES.select{|k,v| k<Product::PRODUCT_END}.values.each do |prod_name|
      Category.create(:name => prod_name, :types =>Category::TYPES[:good], :store_id => store.id)
    end
    Product::PRODUCT_TYPES.select{|k,v| k>=Product::PRODUCT_END}.values.each do |serv_name|
      Category.create(:name => serv_name, :types =>Category::TYPES[:service], :store_id => store.id)
    end
    #---记得哦
    cates = Category.where(:store_id =>store.id ).inject(Hash.new){|hash,ca|
      hash[ca.types].nil? ? hash[ca.types]={ca.name=>ca.id} :  hash[ca.types][ca.name]=ca.id;hash }
    prods = Product.where(:status=>Product::IS_VALIDATE[:YES],:store_id=>store.id).inject(Hash.new){|hash,prod|
      prod_types = prod.is_service ? "service" : "prod";
      hash[prod_types].nil? ? hash[prod_types]=[prod] : hash[prod_types] << prod;hash}
    prods["prod"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:good]][Product::PRODUCT_TYPES[pro.types]])} if cates[Category::TYPES[:good]] && prods["prod"]
    prods["service"].each {|pro| pro.update_attributes(:category_id=>cates[Category::TYPES[:service]][Product::PRODUCT_TYPES[pro.types]],:single_types=>Product::SINGLE_TYPE[:SIN])} if cates[Category::TYPES[:service]] && prods["service"]
    materials = Material.where(:status=>Material::STATUS[:NORMAL],:store_id=>store.id)
    materials.each {|mat| mat.update_attributes(:category_id=>cates[Category::TYPES[:material]][Material::TYPES_NAMES[mat.types]])} if cates[Category::TYPES[:material]] && materials
  end
end

#更新收银和财务管理
task(:new_menu => :environment) do
  Menu.delete_all(:controller=>["pay_cash","finances"])
  menu1 = Menu.create(:controller=>"pay_cash",:name=>"收银")
  menu2 = Menu.create(:controller=>"finances",:name=>"财务管理")
  Store.where(:status=>Store::STATUS[:OPENED]).each do |store|
    roles = Role.where(:store_id=>store.id).where("name like '%管理员%' or name like '%店长%' or name like '%老板%'")
    roles.each do |role|
      [menu1,menu2].each do |m|
        RoleMenuRelation.delete_all(:role_id=>role.id, :menu_id => m.id)
        RoleModelRelation.delete_all(:role_id => role.id, :num => Staff::STAFF_MENUS_AND_ROLES[m.controller.to_sym],
          :model_name => m.controller)
        RoleMenuRelation.create(:role_id => role.id, :menu_id => m.id)
        RoleModelRelation.create(:role_id => role.id, :num => Staff::STAFF_MENUS_AND_ROLES[m.controller.to_sym],
          :model_name => m.controller)
      end
    end
  end
end

#更新套餐卡内价格
task(:pcard_percent => :environment) do
  pcards = PackageCard.where(:status=>PackageCard::STAT[:NORMAL])
  pcardProd = PcardProdRelation.where(:package_card_id=>pcards.map(&:id)).group_by{|i|i.package_card_id}
  prods = Product.find(pcardProd.values.flatten.map(&:product_id)).inject({}){|h,p|h[p.id]=p.sale_price.nil? ? 0 : p.sale_price;h}
  pcards.each do |pcard|
    if pcardProd[pcard.id]
      total_price = pcardProd[pcard.id].inject(0){|sum,v|sum + (prods[v.product_id]*v.product_num)}
      if total_price > pcard.price.to_f
        pcard.update_attributes(:sale_percent=>pcard.price.to_f/total_price)
      end
    end
  end
end

#更新储值卡密码
task(:sv_pwd => :environment) do
  time = Time.now.to_i
  count = CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid]).where("password is null").select("count(*) count").count
  CSvcRelation.where(:status=>CSvcRelation::STATUS[:valid]).where("password is null").update_all :password=>Digest::MD5.hexdigest("123456")
  p "update who has bought sv_cards,the bought_records count is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end



#添加供应商助记码
task(:set_cap_name => :environment) do
  require "toPinyin"
  time = Time.now.to_i
  count = Supplier.count("name is not null")
  Supplier.where("name is not null").map{|supplier|
    supplier_name = Supplier.where("name is not null").map(&:cap_name)
    cap_name = supplier.name.split(" ").join("").split("").compact.map{|n|n.pinyin[0][0] if n.pinyin[0]}.compact.join("")
    supplier.update_attributes(:cap_name=>(supplier_name.include? cap_name) ? "#{cap_name}1" : cap_name)}
  "set the cap_name to suppliers,the  num is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end

#更新物料是否添加产品
task(:set_create_prod => :environment) do
  time = Time.now.to_i
  Material.where(:status=>Material::STATUS[:NORMAL]).update_all(:create_prod=>Material::STATUS[:NORMAL])
  count = Product.where(:status=>Product::IS_VALIDATE[:YES],:is_service=>Product::PROD_TYPES[:PRODUCT]).count
  prods = Product.where(:status=>Product::IS_VALIDATE[:YES],:is_service=>Product::PROD_TYPES[:PRODUCT])
  Material.where(:id=>ProdMatRelation.where(:product_id=>prods.map(&:id)).map(&:material_id)).update_all(:create_prod=>Material::STATUS[:DELETE])
  p "set the create prod  to materials,the  num is #{count},the run time is #{(Time.now.to_i - time)/3600.0}"
end

task(:new_types => :environment) do
  types = {Category::TYPES[:OWNER]=>["现金","支票","银行卡","优惠"],Category::TYPES[:ASSETS]=>["生产设备","办公家具","电子电器","车辆","房产","其他"]}  #收付款方式
  time = Time.now.to_i
  c_types = []
  types.each do |k,v|
    v.each{|name|  c_types << Category.new(:types=>k,:name=>name)}
  end
  Category.import c_types
  p "set the create prod  to materials,the  num is #{types.values.flatten().length},the run time is #{(Time.now.to_i - time)/3600.0}"
end

#------------3月3号已未更新
#上海系统数据导入  需要删除文件最后一行防止乱码和错误
task(:import_new_data_sh => :environment) do
  time = Time.now.to_i
  CarNum.import_d(6)  #参数设置为要导入的门店id
  p "the run time is #{(Time.now.to_i - time)/3600.0}"
end



def self.add_length(len,str)
  return "0"*(len-"#{str}".length)+"#{str}"
end

task(:update_svc_card_sh => :environment) do
  require 'spreadsheet'
  time = Time.now.to_i
  store_id = 100028
  sv_card_id = 85
  path = "#{Constant::LOCAL_DIR}wating_data/"
  num_customers = CarNum.joins(:customer_num_relation=>{:customer=>:customer_store_relations}).
    where(:"customer_store_relations.store_id"=>store_id).select("num,customer_num_relations.customer_id c_id").inject({}){|h,c|h[c.num]=c.c_id;h}
  cm = CarModel.all.inject({}){|h,cm|h[cm.id]=cm.name;h} #车牌数据
  svcard_use_records,uncompared,vips,c_store_ralation,c_num_relation = [],[],[],[],[]
  Spreadsheet.open path+"cards.xls" do |book|  #客户表  使用block可以关闭文件
    sheet = book.worksheet 0
    sheet.each_with_index do |row,index|
      if index != 0
        customer_id = num_customers[row[2]]
        if num_customers[row[2]].nil?
          car_model_id = nil
          out = false
          car_name = (row[28]|row[27]).strip.split(" ").join("")
          if car_name.length > 1
            c_name = car_name.split("")
            (0..(c_name.length-1)).each do |i|
              break if out
              if c_name.length != (i+1)
                ((i+1)..c_name.length).each do |j|
                  break if out
                  cm.each{|k,v|
                    if v[c_name[i..j].join("")] #匹配到的车牌
                      car_model_id = k
                      if v.length == car_name.length #匹配到而且字数一致
                        out = true
                        break
                      end
                    end
                  }
                end
              end
            end
          end
          #如果客户不存在  则创建新客户
          car_num = {:num=>row[2],:car_model_id=>car_model_id,:buy_year=>row[25].nil? ? 2013 : row[25].to_datetime.strftime("%Y")}
          v = {:name=>row[3],:mobilephone=>row[7]|row[8],:address=>row[5],:created_at=>row[37]}
          cu = Customer.create(v)
          customer_id = cu.id
          c_store_ralation << CustomerStoreRelation.new(:store_id=>store_id,:customer_id=>cu.id)
          cn = CarNum.create(car_num)
          c_num_relation << CustomerNumRelation.new(:car_num_id=>cn.id,:customer_id=>cu.id)
          uncompared << row.inject([]){|arr,r|arr << r}
        end
        parms = {:customer_id=>customer_id,:sv_card_id=>sv_card_id,:total_price=>row[14],:is_billing=>!row[12].nil?,
          :left_price=>row[13],:id_card=>row[1],:password=>Digest::MD5.hexdigest("123456"),:status=>CSvcRelation::STATUS[:valid]
        }
        vips << customer_id
        c_svc_relation = CSvcRelation.create(parms)
        svcard_use_records << SvcardUseRecord.new({:c_svc_relation_id=>c_svc_relation.id,:types=>SvcardUseRecord::TYPES[:IN],:use_price=>0,:left_price=>c_svc_relation.total_price})
        svcard_use_records << SvcardUseRecord.new({:c_svc_relation_id=>c_svc_relation.id,:types=>SvcardUseRecord::TYPES[:OUT],:use_price=>row[15],:left_price=>c_svc_relation.left_price})
      end
    end
    #如果判定为有卡用户则更改状态为vip客户
    CustomerStoreRelation.where(:customer_id=>vips,:store_id=>store_id).update_all(:is_vip=>CustomerStoreRelation::IS_VIP[:YES])
    p uncompared.length
    #将重复的数据写入excel表格  手机号会换 名字会重复 所以车牌无法判定的会员在这里存在
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet = book.create_worksheet
    uncompared.each_with_index do |row,index|
      sheet.row(index).concat row
    end
    book.write path +"same_names.xls"
    SvcardUseRecord.import svcard_use_records
    CustomerStoreRelation.import c_store_ralation
    CustomerNumRelation.import c_num_relation
  end
  p "the run time is #{(Time.now.to_i - time)/60.0}"
end

#修改订单对应的技师和提成
task(:create_tech_orders => :environment) do
  time = Time.now.to_i
  order_stations = []
  Order.where(:status=>Order::PRINT_CASH).each do |order|
    order_stations << TechOrder.new(:staff_id=>order.cons_staff_id_1,:order_id=>order.id,:own_deduct=>order.technician_deduct) if order.cons_staff_id_1
    order_stations << TechOrder.new(:staff_id=>order.cons_staff_id_2,:order_id=>order.id,:own_deduct=>order.technician_deduct) if order.cons_staff_id_2
  end
  TechOrder.import order_stations unless order_stations.blank?
  p "the run time is #{(Time.now.to_i - time)/60.0}"
end

#修改客户对应的门店
task(:update_store_id_to_customers => :environment) do
  time = Time.now.to_i
  customer_relations = CustomerStoreRelation.all.inject({}){|h,c|h[c.customer_id]=[c.store_id,c.total_point,c.is_vip];h}
  Customer.where(:status=>Customer::STATUS[:NOMAL]).each do |cu|
    if customer_relations[cu.id]
      cu.update_attributes({:store_id=>customer_relations[cu.id][0],:total_point=>customer_relations[cu.id][1],:is_vip=>customer_relations[cu.id][2]})
    else
      p "#{cu.id} is not a valid customer"
    end
  end
  p "the run time is #{(Time.now.to_i - time)/60.0}"
end




#---下次更新需更改状态--- 05/10记
task(:last_login => :environment) do
  time = Time.now.to_i
  Staff.update_all(:last_login=>Time.now.strftime("%Y-%m-%d %H:%M:%S"))
  p "update staff's time of last login run time #{(Time.now.to_i - time)/3600.0}"
end

#储值卡增加编号
task(:add_id_card => :environment) do
  time = Time.now.to_i
  CSvcRelation.joins(:customer).select("c_svc_relations.id,store_id").inject({}){|h,s|
    h[s.store_id].nil? ? h[s.store_id] =[s.id] : h[s.store_id] << s.id;h
  }.each {|c_svc,v|
    CSvcRelation.find(v).each_with_index do |cs,index|
      cs.update_attributes(:id_card=>add_length(8,index+1))
    end
  }
  p "the run time is #{(Time.now.to_i - time)/60.0}"
end


task(:change_msg => :environment) do
  time = Time.now.to_i
  MessageRecord.delete_all
  SendMessage.delete_all
  Store.update_all(:send_list=>MessageRecord::SET_MESSAGE.keys.join(","))
  p "update store's functions to send message to customers run time #{(Time.now.to_i - time)/3600.0}"
end

#用户删除制定门店的信息
task(:delete_infos => :environment) do
  time = Time.now.to_i
  TechOrder.delete_infos(2)
end