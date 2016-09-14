#encoding: utf-8
class CarNum < ActiveRecord::Base
  belongs_to :car_model
  has_one :customer_num_relation
  has_many :orders
  belongs_to :customer
  has_many :reservations


  def self.load_car_num(ids)
    CarNum.where(:id=>ids).select("id,num").inject({}){|h,c|h[c.id]=c.num;h}
  end

  def self.get_customer_info_by_carnum(store_id, car_num)
    sql = ["select c.id customer_id,c.name,c.mobilephone,c.other_way email, c.property property,c.group_name group_name,
      c.sex,date_format(c.birthday,'%Y-%m-%d') birth,cn.buy_year year,cn.distance distance, cn.id car_num_id,cn.num,
     cm.name model_name,cb.name brand_name from customer_num_relations cnr
      inner join car_nums cn on cn.id=cnr.car_num_id and cn.num= ?
      inner join customers c on c.id=cnr.customer_id and c.status=#{Customer::STATUS[:NOMAL]}
      and c.store_id in (?) left join car_models cm on cm.id=cn.car_model_id
      left join car_brands cb on cb.id=cm.car_brand_id ", car_num, StoreChainsRelation.return_chain_stores(store_id)]
    customer = CustomerNumRelation.find_by_sql sql
    customer[0]
  end


  def self.search_customer(num,store_id)
    Customer.joins(:customer_num_relations=>:car_num).where(:"car_nums.num"=>num,:"customers.store_id"=>store_id).
      select("customers.id,name,mobilephone,other_way,address,group_name").where(:status=>Customer::STATUS[:NOMAL]).first
  end

  def self.get_customer_info_by_phone(store_id, phone)
    sql = ["select c.id customer_id,c.name,c.mobilephone,c.other_way email,c.birthday birth,c.property property,c.group_name group_name,
      c.sex
      from customers c  where c.mobilephone = ?
      and c.status=#{Customer::STATUS[:NOMAL]} and c.store_id in (?)", phone, StoreChainsRelation.return_chain_stores(store_id)]
    customer = CustomerNumRelation.find_by_sql sql
    customer = customer[0]
    customer.birth = customer.birth.strftime("%Y-%m-%d")  if customer && customer.birth
    customer
  end

  def self.add_length(len,str)
    return "0"*(len-"#{str}".length)+"#{str}"
  end

  def self.import_d(store_id)
    begin
      require 'spreadsheet'
      path = "#{Constant::LOCAL_DIR}wating_data/"
      Customer.transaction do
        cates = Category.where(:store_id=>store_id,:types=>[Category::TYPES[:material],Category::TYPES[:good]]).group_by{|i| i.types}
        ca_id = cates[Category::TYPES[:material]].map(&:id)[0]
        cap_id = cates[Category::TYPES[:good]].map(&:id)[0]
        cm = CarModel.all.inject({}){|h,cm|h[cm.id]=cm.name;h} #车牌数据
        car_nums,customers,c_orders,materials,order_ids,n_orders,order_prod,pro_num = {},{},{},{},{},{},{},{}
        c_num_relation,prod_mat_relation,order_prod_relation,order_pay_type = [],[],[],[]
        #    same_name,names,total_rows = [],{},{}
        Spreadsheet.open path+"rpprocesshead.xls" do |book|  #客户表  使用block可以关闭文件
          sheet = book.worksheet 0
          sheet.each_with_index do |row,index|
            #58 车型 98车牌 114客户编号
            if index !=0 and row[58]
              car_model_id = nil
              out = false
              car_name = row[58].strip.split(" ").join("")
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
              #          if names.keys.include? row[22].strip    #判断名称是否重复，如果重复则删除已存在的数据
              #            index_info = names[row[22].strip]
              #            same_name << sheet[index_info[1]]
              #            same_name << row
              #            customers.delete(index_info[0])
              #          else
              car_nums["#{row[114]}-#{row[98]}"] = {:num=>row[98],:car_model_id=>car_model_id,:buy_year=>row[11].nil? ? 2013 : row[11].to_datetime.strftime("%Y"),:distance=>row[55]}
              #加上车牌 假定数据中车牌和编号是一致的，一个客户对应一个车牌
              customers["#{row[114]}-#{row[98]}"] = {:name=>row[22],:mobilephone=>row[83].nil? ? row[119] : row[83],:store_id=>store_id}
              c_orders["#{row[114]}-#{row[98]}"].nil? ? c_orders["#{row[114]}-#{row[98]}"]=[row[46].strip=>[row[30],row[11]]] : c_orders["#{row[114]}-#{row[98]}"] << {row[46].strip=>[row[30],row[11]]}
            end
          end
        end
        repaire_book = Spreadsheet.open path+"rpplus.xls" do |repaire_book| #维修工单
          repaire_sheet = repaire_book.worksheet 0
          repaire_sheet.each_with_index do |row,index|
            name = row[16].strip.gsub(/(\(|（)[^（\(\)）]*?(\)|）)、\*\/\D.\d./, "").strip.force_encoding("UTF-8")
            if index !=0 && name != "" && name.length >0
              materials[name]={:name=>name,:price=>row[5],:sale_price=>row[18],:import_price=>row[18],:storage=>0,
                :category_id=>ca_id,:status=>0,:store_id=>store_id,:create_prod=>1}
              order_ids[name].nil? ? order_ids[name]=[row[12].strip]  : order_ids[name] << row[12].strip
              pro_num[row[12].strip].nil? ? pro_num[row[12].strip] = [row[18]] : pro_num[row[12].strip] << row[23]
            end
          end
        end
   
        customers.each do |k,v|
          cu = Customer.create(v)
          cn = CarNum.create(car_nums[k])
          c_num_relation << CustomerNumRelation.new(:car_num_id=>cn.id,:customer_id=>cu.id)
          n_orders["#{cu.id}-#{cn.id}"] = c_orders[k]
        end
        materials.each do |k,v|
          material = Material.create(v)
          parm = {:name=>material.name,:base_price=>material.import_price,:sale_price=>material.import_price,:status=>1,:is_service=>0,
            :store_id=>store_id,:category_id=>cap_id}
          product = Product.create(parm)
          prod_mat_relation << ProdMatRelation.new(:product_id=>product.id,:material_num=>1,:material_id=>material.id)
          order_ids[k].each do |order_p|
            order_prod[order_p].nil? ? order_prod[order_p]=[product.id] : order_prod[order_p] << product.id
          end
        end
        n_orders.each do |k,v|
          v.each do |h|
            h.each_pair{|key,value|
              order_parm = {:car_num_id=>k.split("-")[1],:customer_id=>k.split("-")[0],:price=>value[0],:status=>Order::STATUS[:BEEN_PAYMENT],
                :store_id=>store_id,:code=>store_id.to_s + value[1].strftime("%Y%m%d%H%M%S"),:created_at => value[1]}
              order = Order.create(order_parm)
              order_pay_type << OrderPayType.new(:order_id=>order.id,:pay_type=>0,:price=>value[0],:created_at => value[1])
              order_prod[key].each do |prod|
                order_prod_relation << OrderProdRelation.new(:order_id=>order.id,:product_id=>prod,:price=>0,:total_price=>0,:pro_num=>1)
              end unless order_prod[key].nil?
            }
          end
        end
        OrderPayType.import order_pay_type
        OrderProdRelation.import order_prod_relation
        ProdMatRelation.import prod_mat_relation
        CustomerNumRelation.import c_num_relation
      end
    rescue => error
      p "---error ---"
      p error
    end
  end
end
