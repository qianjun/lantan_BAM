#encoding: utf-8
require 'fileutils'
class MaterialsInOutsController < ApplicationController
  before_filter :sign?
  before_filter :find_store
  layout "mat_in_out", :except => [:create_materials_in]

  def get_material
    material = Material.normal.find_by_code_and_store_id(params[:code], @store.id)
    if material.nil?
      render :text => 'fail'
    else
      if params[:action_name]=='m_in'
        temp_material_orders = material.material_orders.not_all_in
        material_orders = get_mo(material, temp_material_orders)
        material_in ={}
        material_in[material] = material_orders
        render :partial => 'material_in', :locals =>{:material_in => material_in}
      else
        render :partial => 'material_out', :locals =>{:material_out => material}
      end
    end
  end

  def create_materials_in
    status = 1
    #    begin
    @mat_in_list = parse_mat_in_list(params['mat_in_items'])
    #    rescue
    #      status = 0
    #    end
    respond_to do |format|
      format.json{
        render :json => {:status => status}
      }
    end
  end
  
  def create_materials_out
    begin
      params['material_order'].values.each do |mo|
        mat_out_order = MatOutOrder.create(mo.merge(params[:mat_out]).merge({:store_id => @store.id}))
        if mat_out_order.save
          material = Material.find(mat_out_order.material_id)
          material.storage -= mat_out_order.material_num
          material.save
          mat_out_order.update_attribute(:detailed_list,material.detailed_list)
        end
      end
      flash[:notice] = '商品已成功出库！'
      redirect_to "/materials_in_outs"
    rescue
      flash[:notice] = '请录入商品！'
      redirect_to "/stores/#{@store.id}/materials_out" and return
    end
  end

  def save_cookies
    staff_name = Staff.find(params[:staff_id]).name
    cookies[:user_id]={:value =>params[:staff_id], :path => "/", :secure  => false}
    cookies[:user_name]={:value =>staff_name, :path => "/", :secure  => false}
    render :text => 'successful'
  end

  def upload_code_matin
    code_file = params[:code_file]
    if code_file
      new_name = random_file_name(code_file.original_filename) + code_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_IN_PATH % @store.id
      file_path = Material::MAT_IN_PATH % @store.id + "/#{new_name}"
      File.new(file_path, 'a+')
      File.open(file_path, 'wb') do |file|
        file.write(code_file.read)
      end
      
      if File.exists?(file_path)
        @code_num = {}
        File.open(file_path, "r").each_line do |line|
          #6922233613731,10
          data = line.strip.split(',')
          @code_num[data[0]] = data[1]
        end
        @material_ins = []
        materials = Material.where(:code => @code_num.keys, :store_id => @store.id)
        @no_material_codes = (@code_num.keys - materials.map(&:code)) || []
        materials.each do |material|
          temp_material_orders = material.material_orders.not_all_in
          material_orders = get_mo(material, temp_material_orders)
          material_orders.each do |mo|
            mm ={:mo_code => mo.code, :mo_id => mo.id, :mat_code => material.code,
              :mat_name => material.name, :mat_price => material.price}
            @material_ins << mm
          end
        end if materials
      end
    end
  end

  def upload_code_matout
    code_file = params[:code_file]
    if code_file
      new_name = random_file_name(code_file.original_filename) + code_file.original_filename.split(".").reverse[0]
      FileUtils.mkdir_p Material::MAT_OUT_PATH % @store.id
      file_path = Material::MAT_OUT_PATH % @store.id + "/#{new_name}"
      File.new(file_path, 'a+')
      File.open(file_path, 'wb') do |file|
        file.write(code_file.read)
      end

      if File.exists?(file_path)
        @code_num = {}
        File.open(file_path, "r").each_line do |line|
          #6922233613731,10
          data = line.strip.split(',')
          @code_num[data[0]] = data[1]
        end
        @material_ins = []
        @material_outs = Material.where(:code => @code_num.keys, :store_id => @store_id)
      end
    end
  end

  protected

  def find_store
    @store = Store.find_by_id(params[:store_id])
  end

  def parse_mat_in_list(mat_in_items)
    MatInOrder.transaction do 
      mat_in_order = []
      material_orders = MaterialOrder.where(:id=>mat_in_items.keys).inject({}){|h,m|h[m.id]=m;h}
      mat_in_items.each do |k,v|
        materials = Material.where(:id=>v.keys)
        mat_price = {}
        materials.each do |material|
          num = v["#{material.id}"].to_i
          mat_in_order <<  MatInOrder.new({:material => material, :material_order_id => k,
              :material_num =>num , :price => material.import_price, :staff_id => cookies[:user_id],:remark=>"订货单#{material_orders[k.to_i].code}入库记录" })
          storage_price = material.storage.to_i * material.price #库存的总价值
          ruku_price = num * material.import_price #入库的总价值
          avg_price = (ruku_price + storage_price)*1.0/(material.storage.to_i+num) #加权之后的成本价
          material.update_attributes(:storage=>material.storage.to_i + num,:price=>avg_price.round(2))
          mat_price[material.id]=avg_price.round(2)  if material.create_prod
        end
        prod_mat = ProdMatRelation.joins(:product).where(:material_id=>mat_price.keys,:"products.is_service"=>Product::PROD_TYPES[:PRODUCT]).inject({}){|h,p|h[p.product_id]={:t_price=>mat_price[p.material_id]};h}
        Product.update(prod_mat.keys,prod_mat.values)  #更新物料对应的产品的成本价
      end
      MatInOrder.import mat_in_order
      MatOrderItem.where(:material_order_id=>mat_in_items.keys).inject({}) {|h,m|
        if  h[m.material_order_id].nil?
          h[m.material_order_id]={m.material_id=>m.material_num}
        else
          h[m.material_order_id][m.material_id]=m.material_num
        end;h}.each do |k,v|
        full = true
        MatInOrder.where(:material_id => v.keys, :material_order_id =>k).select("sum(material_num) num,material_id").group("material_id").each{  |mat_in|
          full = false if mat_in.num < v[mat_in.material_id]
        }
        material_orders[k].update_attributes(:m_status => 3) if full and material_orders[k]
      end
    end
  end
end