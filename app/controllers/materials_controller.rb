#encoding:utf-8
class MaterialsController < ApplicationController
  require 'uri'
  require 'net/http'
  require 'will_paginate/array'
  #  require 'barby'
  #  require 'barby/barcode/ean_13'
  #  require 'barby/outputter/custom_rmagick_outputter'
  #  require 'barby/outputter/rmagick_outputter'
  layout "storage", :except => [:print,:check_mat_num,:print_mat]
  respond_to :json, :xml, :html
  before_filter :sign?,:except=>["alipay_complete"]
  before_filter :material_order_tips, :only =>[:index, :receive_order, :tuihuo, :check]
  before_filter :make_search_sql, :only => [:search_materials, :page_materials, :page_ins, :page_outs,:print_out]
  before_filter :get_store, :only => [:index, :search_materials, :page_materials, :page_ins, :page_outs, :check_mat_num, :page_materials_losses, :check]
  @@m = Mutex.new

  #库存列表
  def index
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    #@h_types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], 0])
    @material_losses = MaterialLoss.loss_list(@current_store.id).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @materials = Material.materials_list(@current_store.id)
    @materials_storages = @materials.paginate(:per_page => Constant::MORE_PAGE, :page => params[:page])
    @start_time =  Time.now.beginning_of_month.strftime("%Y-%m-%d")
    @end_time =  Time.now.strftime("%Y-%m-%d")
    out_arr = MatOutOrder.out_list(@current_store.id,@start_time,@end_time)
    @out_records = out_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @out_arr = [out_arr[1], out_arr[2]]
    in_arr = MatInOrder.in_list(@current_store.id,@start_time,@end_time)
    @in_records = in_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @in_arr = [in_arr[1], in_arr[2]]
    @type = 0
    @staffs = Staff.all(:select => "s.id,s.name",:from => "staffs s",
      :conditions => "s.store_id=#{@current_store.id} and s.status=#{Staff::STATUS[:normal]}")
    @status = params[:status] if params[:status]
    head_order_records = MaterialOrder.material_order_list(@current_store.id,nil,nil,nil,nil,0)
    @head_order_records = head_order_records[0].paginate(:per_page => 10, :page => params[:page])
    @head_total_money = head_order_records[1]
    @head_pay_money = head_order_records[2]
    @head_total_count = head_order_records[3]
    supplier_order_records = MaterialOrder.material_order_list(@current_store.id,nil,nil,nil,nil,nil)
    @supplier_order_records = supplier_order_records[0].paginate(:per_page => 10, :page => params[:page])
    @supp_total_money = supplier_order_records[1]
    @supp_pay_money = supplier_order_records[2]
    @supp_total_count = supplier_order_records[3]
    @material_order_urgent = MaterialOrder.where(:id => @material_pay_notices.map(&:target_id))
    @mat_in = params[:mat_in] if params[:mat_in]
    @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],@current_store.id, Material::IS_IGNORE[:NO]])  #查出所有该门店的低于门店物料预警数目的物料
    @back_good_records = BackGoodRecord.back_list(@current_store.id).paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
    @suppliers = Supplier.all(:select => "s.id,s.name,s.cap_name", :from => "suppliers s",:conditions => "s.store_id=#{@current_store.id} and s.status=0")
    date_now = Time.now.to_s[0..9]
    before_thirty_day =  (Time.now - 30.day).to_s[0..9]
    @unsalable_materials = Material.find_by_sql("select * from materials where id not in (SELECT material_id as id FROM mat_out_orders  where created_at >= '#{before_thirty_day} 00:00:00' and created_at <= '#{date_now} 23:59:59'
      and  types = 3 and store_id = #{@current_store.id} group by material_id having count(material_id) >= 1) and store_id = #{@current_store.id} and status != #{Material::STATUS[:DELETE]} and created_at < '#{before_thirty_day} 00:00:00';")
    #入库查询状态未完全入库的订货单号
    @material_orders_not_all_in = MaterialOrder.joins(:materials).where("material_orders.m_status not in (?) and material_orders.status != ? and material_orders.store_id = ?",[3,4], MaterialOrder::STATUS[:cancel], params[:store_id]).order("material_orders.created_at desc").select("material_orders.id, material_orders.code").uniq

    respond_to do |format|
      format.html
      format.js
    end
  end

  def search_materials
    @tab_name = params[:tab_name]
    if @tab_name == 'materials' and params[:mat_in_flag]!="1"
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
      @materials = Material.materials_list(@current_store.id, @mat_type.to_i, @mat_name, @mat_code)
      @materials_storages = @materials.paginate(:per_page => Constant::MORE_PAGE, :page => params[:page])
    elsif @tab_name == "material_losses_materials"
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
      @mat_loss_search_materials = Material.materials_list(@current_store.id, @mat_type.to_i, @mat_name, @mat_code)
      #.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    elsif @tab_name == 'material_losses'
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
      @material_losses = MaterialLoss.loss_list(@current_store.id, @mat_type.to_i, @mat_name, @mat_code)
      .paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    elsif  @tab_name == 'in_records'
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
      in_arr = MatInOrder.in_list(@current_store.id,@start_time,@end_time, @mat_type.to_i, @mat_name, @mat_code)
      @in_records = in_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
      @in_arr = [in_arr[1], in_arr[2]]
    elsif @tab_name == 'out_records'
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
      out_arr = MatOutOrder.out_list(@current_store.id,@start_time,@end_time, @mat_type.to_i, @mat_name, @out_types)
      @out_records = out_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
      @out_arr = [out_arr[1], out_arr[2]]
    end
    if params[:mat_in_flag]=="1"
      materials = Material.joins(:material_orders).where(["materials.status = ? and materials.store_id = ?", Material::STATUS[:NORMAL], @current_store.id]).where(
        @s_sql[0]).where(@s_sql[1]).where(@s_sql[2]).where(@s_sql[3]).uniq
      @material_ins = []
      materials.each do |material|
        if params[:mo_code].present?
          temp_material_orders = MaterialOrder.where({:id => params[:mo_code]})
        else
          temp_material_orders = material.material_orders.not_all_in
        end        
        material_orders = get_mo(material, temp_material_orders)
        material_orders.each do |mo, left_num|
          mm ={:mo_code => mo.code, :mo_id => mo.id, :mat_code => material.code,:mat_num => left_num,
            :mat_name => material.name,:mat_unit => material.unit, :mat_price => material.price, :mat_id => material.id}
          @material_ins << mm
        end
      end if materials
    end
  end

  #库存列表分页
  def page_materials
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    @materials = Material.materials_list(@current_store.id, @mat_type.to_i, @mat_name, @mat_code)
    @materials_storages = @materials.paginate(:per_page => Constant::MORE_PAGE, :page => params[:page])
    respond_with(@materials_storages) do |format|
      format.js
    end
  end

  #入库列表分页
  def page_ins
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    in_arr = MatInOrder.in_list(@current_store.id,@start_time,@end_time, @mat_type.to_i, @mat_name, @mat_code)
    @in_records = in_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @in_arr = [in_arr[1], in_arr[2]]
    respond_with(@in_records) do |f|
      f.html
      f.js
    end
  end

  #出库列表分页
  def page_outs
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    p @out_types
    out_arr = MatOutOrder.out_list(@current_store.id,@start_time,@end_time, @mat_type.to_i, @mat_name, @out_types)
    @out_records = out_arr[0].paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @out_arr = [out_arr[1], out_arr[2]]
    respond_with(@out_records) do |f|
      f.html
      f.js
    end
  end

  #向总部订货分页
  def page_head_orders
    store_id = params[:store_id].to_i
    m_status = params[:m_status].to_i
    from = params[:from]
    to = params[:to]
    status = params[:status].to_i
    records = MaterialOrder.material_order_list(store_id, status,m_status,from,to,0)
    @head_order_records = records[0].paginate(:per_page => 10, :page => params[:page])
    @head_total_money = records[1]
    @head_pay_money = records[2]
    @head_total_count = records[3]
    respond_with(@head_order_records) do |f|
      f.html
      f.js
    end
  end

  #向供应商订货分页
  def page_supplier_orders
    store_id = params[:store_id].to_i
    m_status = params[:m_status].to_i
    from = params[:from]
    to = params[:to]
    status = params[:status].to_i
    supp = params[:supp].to_i==0 ? nil : params[:supp].to_i
    records = MaterialOrder.material_order_list(store_id, status,m_status,from,to,supp)
    @supplier_order_records = records[0].paginate(:per_page => 10, :page => params[:page])
    @supp_total_money = records[1]
    @supp_pay_money = records[2]
    @supp_total_count = records[3]
    respond_with(@supplier_order_records) do |f|
      f.html
      f.js
    end
  end

  #库存报损分页
  def page_materials_losses
    @mat_code = params[:mat_code]
    @mat_name = params[:mat_name]
    @mat_type = params[:mat_type]
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    @material_losses = MaterialLoss.loss_list(@current_store.id, @mat_type.to_i, @mat_name, @mat_code)
    .paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    respond_with(@material_losses) do |format|
      format.html
      format.js
    end
  end

  #退货记录分页
  def page_back_records
    @current_store = Store.find_by_id(params[:store_id].to_i)
    @back_type = params[:back_type]
    @back_name = params[:back_name]
    @back_code = params[:back_code]
    @back_supp = params[:back_supp]
    @back_good_records = BackGoodRecord.back_list(@current_store.id,@back_type.to_i,@back_name,@back_code,@back_supp.to_i)
    .paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
    respond_with(@back_good_records) do |f|
      f.html
      f.js
    end
  end

  #入库
  def mat_in
    @material = Material.find_by_code_and_status_and_store_id params[:barcode].strip,Material::STATUS[:NORMAL],params[:store_id]
    @material_order = MaterialOrder.find_by_code params[:code].strip
    Material.transaction do
      begin
        if @material
          storage_price = @material.storage.to_i * @material.price
          avg_price = (@material_order.price + storage_price)*1.0/(@material.storage.to_i+params[:num].to_i)
          @material.update_attribute({:storage=>@material.storage.to_i + params[:num].to_i,:price=>avg_price})
          Product.find(@material.prod_mat_relations[0].product_id).update_attributes(:t_price=>avg_price)  if @material.create_prod
        else
          @material = Material.create({:code => params[:barcode].strip,:name => params[:name].strip,
              :price => params[:price].strip, :storage => params[:num].strip,
              :status => Material::STATUS[:NORMAL],:store_id => params[:store_id],
              :types => params[:material][:types], :is_ignore => Material::IS_IGNORE[:NO],
              :material_low => Material::DEFAULT_MATERIAL_LOW,:import_price => params[:price].strip})
        end
        if @material_order
          MatInOrder.create({:material => @material, :material_order => @material_order, :material_num => params[:num],
              :price => params[:price],:staff_id => cookies[:user_id],:remark=>"分批入库记录"})
          #检查是否可以更新成已入库状态
          if @material_order.check_material_order_status
            @material_order.m_status = 3
            @material_order.save
          end
        else
          MatInOrder.create({:material => @material, :material_num => params[:num],:price => params[:price],
              :staff_id => cookies[:user_id]})
        end
      rescue

      end
    end
    redirect_to store_materials_path(params[:store_id])
  end

  #判断订货数目与入库数目是否一致
  def check_nums
    notice = true
    begin
      mat_info = {}
      msg = ""
      material_order = MaterialOrder.where(:id=>params[:mat_mos].keys,:store_id => params[:store_id]).inject({}){|h,m|h[m.id]=m.code;h}
      params[:mat_mos].each do |k,v|
        msg += "订货单#{material_order[k.to_i]}："
        mat_info[k] = {} if mat_info[k].nil?
        materials = Material.where(:code=>v.keys,:status=>Material::STATUS[:NORMAL],:store_id => params[:store_id]).inject({}){|h,m|h[m.id]=m;h}
        mi_num = MatInOrder.where(:material_id =>materials.keys, :material_order_id =>k).
          select("material_id id,sum(material_num) num").group("material_id").inject({}){|h,mi|h[mi.id]=mi.num;h}
        mo_num = MatOrderItem.where(:material_id=>materials.keys,:material_order_id =>k).inject({}){|h,mo|h[mo.material_id]=mo.material_num;h}
        mat_info[k] = {} if mat_info[k].nil?
        msg_con = []
        materials.each {|m1,m2|
          mat_info[k][m1]=v[m2.code]
          p mo_num[m1] ||= 0
          p (mi_num[m1] ||= 0)+v[m2.code].to_i
          if (mi_num[m1] ||= 0)+v[m2.code].to_i > mo_num[m1] ||= 0
            msg_con << "#{m2.name}：超出#{(mi_num[m1] ||= 0)+v[m2.code].to_i- (mo_num[m1] ||= 0)}#{m2.unit}"
            notice = false
          end}
        msg += msg_con.join("，")
      end
      p mat_info
      render :json=>{:notice=>notice,:mat_info=>mat_info,:msg=>msg}
    rescue
      render  :json=>{:notice=>false,:msg=>"数据错误"}
    end
  end

  #备注
  def remark
    material =  Material.new(:unit=>"11",:code_value=>"4042216269563")
    material.save
    material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
    material.update_attribute(:remark,params[:remark]) if material
    render :text => 1
  end

  #显示备注框
  def get_remark
    @store = Store.find params[:store_id]
    @material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
  end

  #核实
  def check
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]])
    Material.transaction do
      @material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
      @pandian_flag = params[:pandian_flag].to_i
      num = @material.storage
      if @material.update_attributes(:storage => params[:num].to_i+num, :check_num => nil)
        import_price = @material.import_price.nil? ? @material.price : @material.import_price
        material_order = MaterialOrder.create({:price =>(params[:num].to_i)*import_price,:remark=>"快速入库",
            :code => MaterialOrder.material_order_code(params[:store_id].to_i), :status => MaterialOrder::STATUS[:pay],
            :m_status => MaterialOrder::M_STATUS[:save_in],:staff_id => cookies[:user_id],:store_id => params[:store_id]
          })
        MatOrderItem.create({:material_order => material_order, :material => @material, :material_num =>params[:num].to_i,
            :price =>@material.import_price,:detailed_list=>@material.detailed_list})
        MatInOrder.create({:material => @material, :material_order => material_order,
            :material_num =>params[:num].to_i, :price =>@material.import_price, :staff_id => cookies[:user_id]
          })
        @status = 0
      else
        @status = 1
      end
    end
  end

  #物料查询
  def search
    str = ["status = ?", Material::STATUS[:NORMAL]]
    if params[:name].strip.length > 0
      str[0] += " and name like ?"
      str << "%#{params[:name].gsub(/[%_]/){|x| '\\' + x}}%"
    end
    if params[:types].strip.length > 0
      str[0] += " and types = ?"
      str << "#{params[:types]}"
    end
    if params[:store_id].present?
      str[0] += " and store_id = ?"
      str << "#{params[:store_id]}"
    end
    if params[:type].to_i == 1 && params[:from]
      if params[:from].to_i == 0
        headoffice_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/search_material.json?name=#{params[:name]}&types=#{params[:types]}"
        result = begin
          open(URI.encode(headoffice_api_url.strip), &:read)
        rescue Errno::ETIMEDOUT
          open(URI.encode(headoffice_api_url.strip), &:read)
        end
        @search_materials = JSON.parse(result)
      elsif params[:from].to_i > 0
        @search_materials = Material.materials_list(params[:store_id].to_i,params[:types].to_i,params[:name])
      end
    else
      @search_materials = Material.materials_list(params[:store_id].to_i,params[:types].to_i,params[:name])
    end
    
    @type = params[:type].to_i
    respond_with(@search_materials,@type) do |format|
      format.html
      format.js
    end
  end

  #出库
  def out_order
    status = MatOutOrder.new_out_order params[:selected_items],params[:store_id],params[:staff], params[:types],params[:remark]
    render :json => {:status => status}
  end

  #创建订货记录
  def material_order
    MaterialOrder.transaction do  
      if params[:supplier] and params[:supplier].to_i > 0 and params[:material_order]
        m_order = MaterialOrder.create({:supplier_id => params[:supplier], :supplier_type => Supplier::TYPES[:branch],
            :code => MaterialOrder.material_order_code(params[:store_id].to_i), :status => MaterialOrder::STATUS[:no_pay],
            :m_status => MaterialOrder::M_STATUS[:no_send],:staff_id => cookies[:user_id],:store_id => params[:store_id]})

        mat_order_items,material_import_price,price = [],{},0
        #订单相关的物料
        params[:material_order].each do |m_id,num_price|
          price += num_price[1].to_f * num_price[0].to_i
          mat_order_items << MatOrderItem.new({:material_order => m_order, :material_id =>m_id, :material_num =>num_price[0],:price =>num_price[1].to_f})
          material_import_price[m_id.to_i] = {:import_price => num_price[1].to_f}
        end
        MatOrderItem.import mat_order_items
        m_order.update_attribute(:price,price)
        Material.update(material_import_price.keys,material_import_price.values)
        @material_order = m_order
      end
    end
    @current_store = Store.find_by_id params[:store_id]
    @a = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]]).inject(Hash.new){|h, t|h[t.id]=t.name;h}
    #render :json => {:status => status, :mo_id => material_order.id}
  end

  #退货
  def back_good     #主页面导航栏上的退货
    store_id = params[:store_id].to_i
    suppliers = Supplier.all(:select => "s.id,s.name", :from => "suppliers s",
      :conditions => "s.store_id=#{store_id} and s.status=0")
    @store_id = store_id
    @suppliers = suppliers
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], store_id])
    respond_to do |f|
      f.js
    end
  end

  #退货时查询物料
  def back_good_search
    supp = params[:supplier_id]
    good_type = params[:good_type]
    sql = "select sum(moi.material_num) mnum,moi.material_id mid, mo.supplier_id msuid, m.name mname, m.storage mstorage, c.name cname,
          ifnull(m.import_price,0) import_price from material_orders mo inner join mat_order_items moi on mo.id=moi.material_order_id 
         inner join materials m on moi.material_id=m.id inner join categories c on m.category_id=c.id where mo.supplier_id=#{supp} and
         mo.m_status=#{MaterialOrder::M_STATUS[:save_in]} and c.id=#{good_type} and m.storage > 0"
    unless params[:good_name].strip.empty? || params[:good_name].strip == ""
      good_name = params[:good_name].strip.gsub(/[%_]/){|x|'\\' + x}
      sql += " and m.name like '%#{good_name}%'"
    end
    sql += " group by mid"
    @materials = MaterialOrder.find_by_sql(sql)
    @checked = params[:checked]
  end

  #退货提交
  def back_good_commit
    begin
      MaterialOrder.transaction do
        sup_id = params[:supplier]
        mat_order = MaterialOrder.create({:code => MaterialOrder.material_order_code(params[:store_id].to_i),
            :status => MaterialOrder::STATUS[:no_pay],:remark=>"物料退货返还货款",:store_id => params[:store_id],:supplier_id=>sup_id,
            :m_status => MaterialOrder::M_STATUS[:returned],:staff_id => cookies[:user_id],:supplier_type=>Supplier::TYPES[:branch]})
        total_price = 0
        params[:data].each do |d|
          id = d.split("-")[0].to_i
          num = d.split("-")[1].to_i
          price = d.split("-")[2]
          material = Material.find_by_id(id)
          Material.update_storage(id,material.storage - num,cookies[:user_id],"退货扣除已入库库存",nil) if material
          BackGoodRecord.create(:material_id => id, :material_num => num, :supplier_id => sup_id,
            :store_id => params[:store_id].to_i,:price=>price)
          MatOrderItem.create({:material_order=>mat_order,:material_id => id, :material_num =>num,:price =>price})
          total_price += -num*(price.to_f.round(2))
        end
        mat_order.update_attribute(:price,total_price)
        render :json => 1
      end
    rescue
      render :json => 0
    end
  end
  #付款页面
  def material_order_pay
    types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]])
    @a = types.inject(Hash.new){|h, t|h[t.id]=t.name;h}
    @current_store = Store.find_by_id params[:store_id]
    @store_account = @current_store.account if @current_store
    @material_order = MaterialOrder.find_by_id params[:mo_id]
    #    @use_card_count = SvcReturnRecord.store_return_count(params[:store_id]).try(:abs) # 先不提交
  end

  #检验付款页面的"活动代码"
  def get_act_count
    #puts params[:code]
    sale = Sale.valid.find_by_code params[:code]
    if sale
      material_order = MaterialOrder.find(params[:mo_id])
      mats_codes = material_order.materials.map(&:code)
      sale_materials_codes = sale.products.service.map{|p| p.materials.map(&:code)}.flatten
      match_material = mats_codes&sale_materials_codes
      sale = nil if match_material.empty?
    end
    text = sale.nil? ? "" : sale.sub_content
    sale_id = sale.nil? ? "" : sale.id
    render :json => {:status => 1,:text => text,:sale_id => sale_id}
  end

  #添加物料（供应商订货）
  def add
    #puts params[:store_id]
    material = Material.find_by_code_and_store_id params[:code], params[:store_id]
    material =  Material.create({:code => params[:code].strip,:name => params[:name].strip,
        :price => params[:cost_price].strip.to_i,:sale_price => params[:sale_price].strip.to_i,
        :storage => 0, :material_low => Material::DEFAULT_MATERIAL_LOW,:unit => params[:unit] || "件",
        :status => Material::STATUS[:NORMAL],:store_id => params[:store_id],
        :types => params[:types], :check_num => nil, :is_ignore => Material::IS_IGNORE[:NO]}) if material.nil?
    x = {:status => 1, :material => material}.to_json
    #puts x
    render :json => x
  end

  #查询向总部订货的订单
  def search_head_orders
    store_id = params[:store_id].to_i
    m_status = params[:m_status].to_i
    from = params[:from]
    to = params[:to]
    status = params[:status].to_i
    records = MaterialOrder.material_order_list(store_id, status,m_status,from,to,0)
    @head_order_records = records[0].paginate(:per_page => 10, :page => params[:page])
    @head_total_money = records[1]
    @head_pay_money = records[2]
    @head_total_count = records[3]
    respond_with(@head_order_records) do |f|
      f.html
      f.js
    end
  end

  #查询向供应商订货的订单
  def search_supplier_orders
    #    supplier_id = params[:type] && params[:type].to_i == 1 ? 1 : 0
    #    @supplier_order_records = MaterialOrder.search_orders params[:store_id],params[:from],params[:to],params[:status].to_i,
    #      supplier_id,params[:page],Constant::PER_PAGE,params[:m_status].to_i
    store_id = params[:store_id].to_i
    m_status = params[:m_status].to_i
    from = params[:from]
    to = params[:to]
    status = params[:status].to_i
    supp = params[:supp].to_i==0 ? nil : params[:supp].to_i
    records = MaterialOrder.material_order_list(store_id, status,m_status,from,to,supp)
    @supplier_order_records = records[0].paginate(:per_page => 10, :page => params[:page])
    @supp_total_money = records[1]
    @supp_pay_money = records[2]
    @supp_total_count = records[3]
    respond_with(@supplier_order_records) do |f|
      f.html
      f.js
    end
  end

  #发送充值请求
  def alipay
    options = {
      :service => "create_direct_pay_by_user",
      :notify_url => Constant::SERVER_PATH+"/stores/#{params[:store_id]}/materials/alipay_complete",
      :subject => "订货支付",
      :total_fee => params[:f]
    }
    out_trade_no =params[:mo_code]
    options.merge!(:seller_email =>Oauth2Helper::SELLER_EMAIL, :partner =>Oauth2Helper::PARTNER,
      :_input_charset=>"utf-8", :out_trade_no=>out_trade_no,:payment_type => 1)
    options.merge!(:sign_type => "MD5",:sign =>Digest::MD5.hexdigest(options.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY))
    redirect_to "#{Oauth2Helper::PAGE_WAY}?#{options.sort.map{|k, v| "#{CGI::escape(k.to_s)}=#{CGI::escape(v.to_s)}"}.join('&')}"
  end

  #充值异步回调
  def alipay_complete
    out_trade_no=params[:out_trade_no]
    order = MaterialOrder.find_by_code out_trade_no
    alipay_notify_url = "#{Oauth2Helper::NOTIFY_URL}?partner=#{Oauth2Helper::PARTNER}&notify_id=#{params[:notify_id]}"
    response_txt =Net::HTTP.get(URI.parse(alipay_notify_url))
    my_params = Hash.new
    request.parameters.each {|key,value|my_params[key.to_s]=value}
    my_params.delete("action")
    my_params.delete("controller")
    my_params.delete("sign")
    my_params.delete("sign_type")
    my_params.delete("store_id")
    my_sign = Digest::MD5.hexdigest(my_params.sort.map{|k,v|"#{k}=#{v}"}.join("&")+Oauth2Helper::PARTNER_KEY)
    dir = "#{Rails.root}/public/logs"
    Dir.mkdir(dir)  unless File.directory?(dir)
    file = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+"_alipay.log","a+")
    file.write "#{Time.now.strftime('%Y%m%d %H:%M:%S')}   #{request.parameters.to_s}\r\n"
    if my_sign==params[:sign] and response_txt=="true"
      if params[:trade_status]=="WAIT_BUYER_PAY"
        render :text=>"success"
      elsif params[:trade_status]=="TRADE_FINISHED" or params[:trade_status]=="TRADE_SUCCESS"
        if order
          @@m.synchronize {
            begin
              MaterialOrder.transaction do
                order.update_attribute(:status, MaterialOrder::STATUS[:pay])
                if order.supplier_type==0
                  mat_order_types = order.m_order_types.to_json
                  headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
                  result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => order.code, 'mo_status' => MaterialOrder::STATUS[:pay], 'mo_price' => order.price, 'mat_order_types' => mat_order_types})
                end
                #支付记录
                MOrderType.create(:material_order_id => order.id,:pay_types => MaterialOrder::PAY_TYPES[:CHARGE], :price => order.price)
                render :text=>"success"
              end
            rescue
              render :text=>"success"
            end
          }
        else
          file.puts "#{Time.now.strftime('%Y%m%d %H:%M:%S')} #{out_trade_no} is not Found \r\n"
        end
      else
        render :text=>"fail" + "<br>"
      end
    else
      redirect_to "/"
    end
    file.close
  end

  #打印
  def print
    @current_store = Store.find_by_id(params[:store_id].to_i)
    @materials_storages = Material.materials_list(@current_store.id)
  end


  #获得mat_order 的备注
  def get_mo_remark
    @store = Store.find params[:store_id]
    @material_order = MaterialOrder.find_by_id_and_store_id(params[:mo_id], params[:store_id])
  end
  
  #订货订单的备注
  def order_remark
    order = MaterialOrder.find_by_id_and_store_id(params[:mo_id], params[:store_id]) if params[:mo_id]
    order.update_attribute(:remark, params[:remark]) if order
    render :text => '1'
  end

  #催货
  def cuihuo
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      if order
        Notice.create(:store_id => order.store_id, :content => URGE_GOODS_CONTENT + ",订单号为：#{order.code}",
          :target_id => order.id, :types => Notice::TYPES[:URGE_GOODS])
      end
    end
    render :json => {:status => 1}.to_json
  end
  
  #退货
  def tuihuo
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]])
    @order = MaterialOrder.find_by_id(params[:id].to_i)
    if @order
      if @order.m_status == 3 || @order.m_status == 4
        @status = 0

      else
        if @order.update_attribute("m_status", MaterialOrder::M_STATUS[:returned])
          @status = 1
        else
          @status = 0
        end
      end
    else
      @status = 0
    end
    @content = @status==0 ? "操作失败" : "操作成功"
  end
  #取消订货订单
  def cancel_order
    if params[:order_id]
      order = MaterialOrder.find_by_id params[:order_id]
      content = "订单已取消成功"
      if order && order.status == MaterialOrder::STATUS[:no_pay] && order.m_status == MaterialOrder::M_STATUS[:no_send]
        order.update_attribute(:status,MaterialOrder::STATUS[:cancel])
        if order.supplier_id==0
          headoffice_post_api_url = Constant::HEAD_OFFICE_API_PATH + "api/materials/update_status"
          result = Net::HTTP.post_form(URI.parse(headoffice_post_api_url), {'mo_code' => order.code, 'mo_status' => MaterialOrder::STATUS[:cancel]})
        end
      elsif order.status == MaterialOrder::STATUS[:cancel]
        content = "订单已取消"
      else
        content = "订单已经付款或已发货无法取消"
      end
    end
    render :json => {:status => 1,:content => content}.to_json
  end

  #确认收货
  def receive_order
    if params[:id]
      @order = MaterialOrder.find_by_id params[:id]
      @content = ""
      @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id].to_i])
      if @order #&& @order.m_status == MaterialOrder::M_STATUS[:send]
        @order.update_attribute(:m_status,MaterialOrder::M_STATUS[:received])
        @content = "收货成功"
      elsif @order.m_status == MaterialOrder::M_STATUS[:received]
        @content = "订单已收货"
      end
    end
    #render :json => {:status => 1,:content => content, :order => order}.to_json
  end

  #订单支付
  def pay_order
    begin
      Material.transaction do
        @mat_order = MaterialOrder.find params[:mo_id]
        if params[:pay_type].to_i == 1   #支付宝
          url = "/stores/#{params[:store_id]}/materials/alipay?f="+@mat_order.price.to_s+"&mo_code="+@mat_order.code
          render :json => {:status => -1,:pay_type => params[:pay_type].to_i,:pay_req => url}
        elsif params[:pay_type].to_i == 3 || params[:pay_type].to_i == 4 || params[:pay_type].to_i == 5 #现金已支付 #使用储值卡  #现金未支付
          @mat_order.update_attribute(:status, MaterialOrder::STATUS[:pay]) unless params[:pay_type].to_i == 5
          #支付记录
          MOrderType.create(:material_order_id => @mat_order.id,:pay_types => params[:pay_type], :price => @mat_order.price)
        end
        render :json => {:status => 0}
      end
    rescue
      render :json => {:status => 2}
    end

  end

  #修改提醒状态
  def update_notices
    if params[:ids]
      (params[:ids].split(",") || []).each do |id|
        notice = Notice.find_by_id_and_store_id id.to_i,params[:store_id].to_i
        if notice && notice.status == Notice::STATUS[:NORMAL]
          notice.update_attribute(:status,Notice::STATUS[:INVALID])
        end
      end
    end
    render :json => {:status => 0}
  end
  
  #查看订货单详情
  def mat_order_detail
    @mo = MaterialOrder.find params[:id]
    @store_id = params[:store_id]
    @total_money = 0
    @mo.mat_order_items.each do |moi|
      @total_money += moi.price * moi.material_num
    end
  end

  #判断物料条形码是否唯一
  def uniq_mat_code
    material = Material.find_by_code_and_store_id(params[:code], params[:store_id])
    render :text => material.nil? ? "0" : "1"
  end

  #上传核实文件
  def upload_checknum
    check_file = params[:check_file]
    if check_file
      new_name = random_file_name(check_file.original_filename) + check_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_CHECKNUM_PATH % @store_id
      file_path = Material::MAT_CHECKNUM_PATH % @store_id + "/#{new_name}"
      File.new(file_path, 'a+')
      File.open(file_path, 'wb') do |file|
        file.write(check_file.read)
      end

      if File.exists?(file_path)
        @check_nums = {}
        File.open(file_path, "r").each_line do |line|
          #6922233613731,10
          data = line.strip.split(',')
          @check_nums[data[0]] = data[1]
        end
        @materials = Material.where(:code => @check_nums.keys, :status => Material::STATUS[:NORMAL], :store_id => @store_id)
      end
    end
  end


  #设置库存预警数目
  def set_material_low_commit
    store = Store.find_by_id(params[:store_id].to_i)
    if store.update_attribute("material_low", params[:material_low_value])
      flash[:notice] = "设置成功!"
      redirect_to store_materials_path(store)
    else
      flash[:notice] = "设置失败!"
      redirect_to store_materials_path(store)
    end
  end

  #设置单个库存预警
  def set_material_low_count
    @store_id = params[:store_id].to_i
    @material = Material.find_by_id_and_store_id(params[:id].to_i, @store_id)
  end
  
  #设置单个库存预警提交
  def set_material_low_count_commit
    material = Material.find_by_id_and_store_id(params[:mat_id].to_i,params[:store_id].to_i)
    if material.nil?
      @status = 0
    else
      if material.update_attribute("material_low", params[:low_count].to_i)
        @status = 1
        @material = material
        @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],params[:store_id].to_i, Material::IS_IGNORE[:NO]])
      else
        @status = 0
      end
    end
  end

  def set_ignore   #设置物料忽略预警
    #current_store = Store.find_by_id(params[:store_id].to_i)
    material = Material.find_by_id_and_store_id(params[:m_id].to_i, params[:store_id])
    if material
      if material.update_attribute("is_ignore", Material::IS_IGNORE[:YES])
        render :json => {:status => 1, :material_low => material.material_low, :material_storage => material.storage}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 0}
    end
  end

  def cancel_ignore   #取消设置物料预警
    material = Material.find_by_id_and_store_id(params[:m_id].to_i,params[:store_id].to_i)
    #current_store = Store.find_by_id(params[:store_id].to_i)
    if material
      if material.update_attribute("is_ignore", Material::IS_IGNORE[:NO])
        render :json => {:status => 1, :material_low => material.material_low, :material_storage => material.storage,
          :material_code => material.code, :material_name => material.name,
          :material_type => Material::TYPES_NAMES[material.types], :material_price => material.price}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 0}
    end
  end

  #添加物料
  def new
    @current_store = Store.find_by_id(params[:store_id])
    @material = Material.new
    @cates = Category.where(:types =>[Category::TYPES[:material],Category::TYPES[:good]],:store_id =>@current_store.id).inject({}){
      |hash,ca| hash[ca.types].nil? ? hash[ca.types] = {ca.id => ca.name}:hash[ca.types][ca.id]=ca.name;hash}
  end

  def create
    params[:material][:name] = params[:material][:name].strip
    params[:material][:detailed_list] = params[:material][:detailed_list].strip.gsub("\r\n","<br/>")
    Material.transaction  do
      if params[:material][:ifuse_code]=="1"
        code_value = params[:material][:code_value].strip[0..-2]
        barcode = Barby::EAN13.new(code_value)
        material_tmp = Material.find_by_code_and_store_id_and_status(code_value+barcode.checksum.to_s, params[:store_id], Material::STATUS[:NORMAL])
        if material_tmp
          @status = 2
          @flash_notice = "该物料在当前门店中已经存在！"
        end
      end
      unless material_tmp
        material = Material.new(params[:material].merge({:status => 0, :store_id => params[:store_id].to_i,
              :storage => 0, :material_low => Material::DEFAULT_MATERIAL_LOW}))
        if material.save
          smaterial = SharedMaterial.find_by_code(material.code)
          sm_params = params[:material].except(:sale_price,:ifuse_code,:code_value, :category_id,:create_prod,:detailed_list).merge({:code => material.code})
          SharedMaterial.create(sm_params) if smaterial.nil?
          @status = 0
          @flash_notice = "物料创建成功!"
        elsif material && material.errors.any?
          @flash_notice = "物料创建成功!<br/> #{material.errors.messages.values.flatten.join("<br/>")}"
          @status = 1
        else
          @flash_notice = "物料创建失败!<br/> #{material.errors.messages.values.flatten.join("<br/>")}"
          @status = 2
        end
        set_product(Constant::PRODUCT,material)  if material.create_prod
      end
      respond_to do |f|
        f.js
        f.json {
          render :json => {:status => 0, :material => material}
        }
      end
    end
  end

  def set_product(types,material)
    parms = {:name=>params[:prod_name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:intro],
      :category_id=>params[:prod_types],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:desc], :store_id=>params[:store_id],:t_price=>material.price,
      :is_service=>Product::PROD_TYPES[:"#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"), :service_code=>"#{types[0]}#{Sale.set_code(3,"product","service_code")}",
      :is_auto_revist=>params[:auto_revist],:auto_time=>params[:time_revist],:revist_content=>params[:con_revist],:prod_point=>params[:prod_point]=="" ? 0 : params[:prod_point]}
    parms.merge!(:deduct_price=>params[:deduct_price].nil? ? 0 : params[:deduct_price],:techin_price=>params[:techin_price].nil? ? 0 :params[:techin_price] )
    parms.merge!(:deduct_percent=>params[:deduct_percent].nil? ? 0 : params[:deduct_percent].to_f*params[:sale_price].to_f/100)
    parms.merge!({:techin_percent=>params[:techin_percent].nil? ? 0 : params[:techin_percent].to_f*params[:sale_price].to_f/100})
    added = params[:is_added].nil? ? 0 : params[:is_added]
    parms.merge!({:standard=>params[:standard],:is_added =>added})
    product =Product.create(parms)
    ProdMatRelation.create(:product_id=>product.id,:material_num=>1,:material_id=>material.id)
    begin
      if params[:img_url] and !params[:img_url].keys.blank?
        params[:img_url].each_with_index {|img,index|
          url=Sale.upload_img(img[1],product,Constant::P_PICSIZE<<"#{types.downcase}_pics",img[0])
          ImageUrl.create(:product_id=>product.id,:img_url=>url)
          product.update_attributes({:img_url=>url}) if index == 0
        }
      end
    rescue
      @flash_notice ="图片上传失败，请重新添加！"
    end
  end

  #编辑物料
  def edit
    @current_store = Store.find_by_id(params[:store_id])
    @material = Material.where(:id => params[:id], :store_id => params[:store_id]).first
    @cates = Category.where(:types =>[Category::TYPES[:material],Category::TYPES[:good]],:store_id =>@current_store.id).inject({}){
      |hash,ca| hash[ca.types].nil? ? hash[ca.types] = {ca.id => ca.name}:hash[ca.types][ca.id]=ca.name;hash}
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
  end

  def update
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id].to_i])
    @material = Material.find_by_id(params[:id])
    params[:material][:name] = params[:material][:name].strip
    params[:material][:category_id] = params[:material][:types]
    params[:material][:types] = nil
    params[:material][:detailed_list] = params[:material][:detailed_list].strip.gsub("\r\n","<br/>")
    @cname = Category.find_by_id(params[:material][:category_id].to_i).name
    if @material.update_attributes(params[:material])
      @status = 0
      @flash_notice = "物料编辑成功!"
      set_product(Constant::PRODUCT,@material)  if params[:material][:create_prod].to_i == 1
    else
      @flash_notice = "物料编辑失败!<br/>"
      @status = 2
    end
  end

  def destroy
    material = Material.find_by_id_and_store_id(params[:id], params[:store_id])
    material.update_attribute(:status, Material::STATUS[:DELETE])
    prod_mat = ProdMatRelation.find_by_material_id(material.id)
    Product.where(:id=>prod_mat.product_id).update_all(:status=>Product::IS_VALIDATE[:NO]) if prod_mat
    flash[:notice] = "物料删除成功"
    redirect_to "/stores/#{params[:store_id]}/materials"
  end

  def search_by_code
    @cates = Category.where(:types =>[Category::TYPES[:material],Category::TYPES[:good]],:store_id =>params[:store_id]).inject({}){
      |hash,ca| hash[ca.types].nil? ? hash[ca.types] = {ca.id => ca.name}:hash[ca.types][ca.id]=ca.name;hash}
    @material = SharedMaterial.find_by_code(params[:code]) if params[:code]
  end



  def print_code
    @store_id = params[:store_id]
    @types = @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @store_id])
    @type=2
  end

  def output_barcode
    @data = []
    if params[:mat_in_items].blank?
      prints = params[:print]
      prints.each do |key, value|
        material = Material.find_by_id(key)
        @data << {:num => value[:print_code_num], :code_img => material.code_img,:name=>material.name,:price=>material.sale_price}
      end
    else
      mats = params[:mat_in_items].split(",").map{|mat| mat.split("_")}
      mats.each do |mat|
        material = Material.find_by_code(mat[0])
        @data << {:num => mat[2], :code_img => material.code_img,:name=>material.name,:price=>material.sale_price}
      end
    end
    render :layout => false
  end

  #库存报损
  def mat_loss
    @current_store = get_store
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @current_store.id])
    @staffs = Staff.all(:select => "s.id,s.name",:from => "staffs s",
      :conditions => "s.store_id=#{params[:store_id].to_i} and s.status=#{Staff::STATUS[:normal]}")
  end

  #添加库存报损
  def mat_loss_add
    count = 0
    success = 0
    @current_store = Store.find_by_id(params[:store_id].to_i)
    @status = false
    mat_losses = params[:mat_losses]
    unless mat_losses.nil?
      mat_losses.each do |key,value|
        count +=1
        material = Material.find(mat_losses[key][:mat_id])
        if material
          if MaterialLoss.create({:loss_num =>  mat_losses[key][:mat_num].to_i,
                :material_id => material.id,
                :staff_id => params[:staff],
                :store_id => @current_store.id
              })
            Material.update_storage(material.id,material.storage-mat_losses[key][:mat_num].to_i,cookies[:user_id],"库存报损",nil)
            success += 1
          end
        end
      end
    end
    if count == success
      @status = true
    end
    @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],@current_store.id, Material::IS_IGNORE[:NO]])
    @material_losses = MaterialLoss.loss_list(@current_store.id).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id].to_i])
    @materials_storages = Material.materials_list(@current_store.id).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    respond_to do |f|
      f.js
    end
  end

  #删除库存报损
  def mat_loss_delete
    @current_store = Store.find_by_id(params[:store_id].to_i)
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id].to_i])
    @status = false
    materialloss =  MaterialLoss.find(params[:materials_loss_id].to_i)
    m_id = materialloss.material_id
    m_num = materialloss.loss_num.to_i
    if materialloss.destroy
      @status = true
      @material_losses = MaterialLoss.loss_list(@current_store.id).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
      material = Material.find_by_id(m_id)
      if material
        material.update_attribute("storage",(material.storage.to_i + m_num))
      end
      @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],@current_store.id, Material::IS_IGNORE[:NO]])
      @materials_storages = Material.materials_list(@current_store.id).paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    end
    respond_to do |f|
      f.js
    end
  end

  #修改条形码
  def modify_code
    store_id = params[:store_id].to_i
    mat_id = params[:mat_id].strip
    new_code = params[:new_code]
    Material.transaction do
      barcode = Barby::EAN13.new(new_code)
      if Material.where(["store_id = ? and code = ? and id != ? and status = ?", store_id, new_code+barcode.checksum.to_s, mat_id, Material::STATUS[:NORMAL]]).blank?
        material = Material.find_by_id_and_store_id(mat_id,store_id)
        if material.nil?
          render :json => {:status => 0}
        else
          if !FileTest.directory?("#{File.expand_path(Rails.root)}/public/barcode/#{Time.now.strftime("%Y%m")}")
            FileUtils.mkdir_p "#{File.expand_path(Rails.root)}/public/barcode/#{Time.now.strftime("%Y%m")}"
          end
          barcode.to_image_with_data(:height => 210, :margin => 60, :xdim => 5).write(Rails.root.join('public', "barcode", "#{Time.now.strftime("%Y%m")}", "#{mat_id}.png"))
          if material.update_attributes(:code => new_code+barcode.checksum.to_s, :code_img => "/barcode/#{Time.now.strftime("%Y%m")}/#{mat_id}.png")
            render :json => {:status => 1, :new_code => material.code}
          else
            render :json => {:status => 0}
          end
        end
      else
        render :json => {:status => 2}
      end
    end
  end

  def reflesh_low_materials   #重新加载库存过低的物料
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id].to_i])
    @low_materials = Material.where(["status = ? and store_id = ? and storage<=material_low
                                    and is_ignore = ?", Material::STATUS[:NORMAL],params[:store_id].to_i, Material::IS_IGNORE[:NO]])
  end

  def print_mat
    @mat_out = MatOutOrder.find(params[:mat_id])
    @store = Store.find(params[:store_id])
    
  end

  def print_out
    if params[:tab_name] == 'in_records'
      in_arr = MatInOrder.in_list(params[:store_id],@start_time,@end_time, @mat_type.to_i,@mat_name,@mat_code,params[:mat_ids])
      @in_records = in_arr[0]
      @in_arr = [in_arr[1], in_arr[2]]
    elsif params[:tab_name] == 'out_records'
      out_arr = MatOutOrder.out_list(params[:store_id],@start_time,@end_time, @mat_type.to_i,@mat_name,params[:out_types],params[:mat_ids])
      @out_records = out_arr[0]
      @out_arr = [out_arr[1], out_arr[2]]
    end
    render :layout => false
  end



  protected
  
  def make_search_sql
    mat_code_sql = params[:mat_code].blank? ? "1 = 1" : ["materials.code = ?", params[:mat_code]]
    mat_name_sql = params[:mat_name].blank? ? "1 = 1" : ["materials.name like ?", "%#{params[:mat_name].gsub(/[%_]/){|x| '\\' + x}}%"]
    mat_type_sql = params[:mat_type].blank? || params[:mat_type] == "-1" ? "1 = 1" : ["materials.category_id = ?", params[:mat_type].to_i]
    mo_code_sql = params[:mo_code].blank? ? "1=1" : ["material_orders.id = ?", params[:mo_code]]
    @s_sql = []
    @s_sql << mat_code_sql << mat_name_sql << mat_type_sql << mo_code_sql
    @mat_code = params[:mat_code].blank? ? nil : params[:mat_code]
    @mat_name = params[:mat_name].blank? ? nil : params[:mat_name]
    @mat_type = params[:mat_type].blank? ? nil : params[:mat_type]
    @out_types = params[:out_types].blank? ? nil : params[:out_types]
    @start_time =  params[:first_time].nil? ? Time.now.beginning_of_month.strftime("%Y-%m-%d") : params[:first_time]
    @end_time =  params[:last].nil? ? Time.now.strftime("%Y-%m-%d") : params[:last]
  end

  def get_store
    @current_store = Store.find_by_id(params[:store_id].to_i) || not_found
  end
end