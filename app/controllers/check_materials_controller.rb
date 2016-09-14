#encoding:utf-8
class CheckMaterialsController < ApplicationController
  layout "storage", :except => [:print,:check_mat_num]
  before_filter :sign?
  before_filter :current_store


  #盘点物料清单
  def index
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]])
    sql = "materials.store_id=#{params[:store_id]}"
    if params[:mat_type] && params[:mat_type].to_i >0
      sql += " and materials.category_id=#{params[:mat_type]}"
    end
    if params[:check_status]
      if params[:check_status].to_i == Material::CHECK_NAME[:UNCOMPLETE]
        sql += " and check_num is null"
      elsif params[:check_status].to_i == Material::CHECK_NAME[:OVER]
        sql += " and check_num is not null"
      end
    end
    @materials_need_check = Material.joins(:category).select("materials.*,categories.name cname").
      where(:status=>Material::STATUS[:NORMAL]).where(sql).group("materials.id").order("materials.name")
    respond_to do |format|
      format.html
      format.js
    end
  end


  def check_record
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], params[:store_id]])
    @materials_need_check = load_check(params[:check_status],params[:store_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  #批量核实
  def batch_check
    flash[:notice] = "盘点清单成功！"
    begin
      Material.transaction do
        Material.update(params[:materials].keys,params[:materials].values)
      end
    rescue
      flash[:notice] = "物料核实失败"
    end
    redirect_to "/stores/#{params[:store_id]}/check_materials/check_record"
  end


  def submit_check
    begin
      material_losses =[]
      records = params[:records]
      records.each do |k,v|
        material_losses << MaterialLoss.new({:material_id=>k,:staff_id=>cookies[:user_id],:remark=>v["remark"],:store_id=>params[:store_id],:loss_num=>v["storage"].to_i- v["check_num"].to_i,:types=>MaterialLoss::TYPES[:LESS]}) if v["storage"].to_i > v["check_num"].to_i
        material_losses << MaterialLoss.new({:material_id=>k,:staff_id=>cookies[:user_id],:remark=>v["remark"],:store_id=>params[:store_id],:loss_num=>v["check_num"].to_i-v["storage"].to_i,:types=>MaterialLoss::TYPES[:MORE]}) if v["storage"].to_i < v["check_num"].to_i
      end
      Material.transaction do
        MaterialLoss.import material_losses unless material_losses.blank?
        @msg = "核实完成,记录文件已生成"
        @print_materials = Material.joins(:category).select("materials.*,categories.name cname").
          where(:status=>Material::STATUS[:NORMAL],:"materials.id"=>params[:records].keys).group("materials.id").order("materials.name")
        CheckNum.create(:file_name=>xls_content_for(@print_materials,params[:records],params[:store_id]),:total_num=>@print_materials.length,:store_id=>params[:store_id])
        records.each { |k,v|records[k]["storage"] = records[k]["check_num"];records[k]["check_num"] = nil}
        Material.update(records.keys,records.values)
      end
    rescue
      @msg = "核实失败"
    end
    @materials_need_check = load_check(params[:check_status],params[:store_id])
  end


  def file_list
    @check_nums = CheckNum.where(:store_id=>params[:store_id]).order("created_at")
  end

 

  private

  def load_check(check_status,store_id)
    sql = "materials.store_id=#{store_id} and check_num is not null"
    if check_status
      if check_status.to_i == Material::RECORD_NAME[:LESS]
        sql += " and storage > check_num"
      elsif check_status.to_i == Material::RECORD_NAME[:EQUAL]
        sql += " and storage = check_num"
      elsif check_status.to_i == Material::RECORD_NAME[:MORE]
        sql += " and storage < check_num"
      end
    end
    Material.joins(:category).select("materials.*,categories.name cname").
      where(:status=>Material::STATUS[:NORMAL]).where(sql).group("materials.id").order("materials.name")
  end

  def current_store
    @current_store = Store.find_by_id(params[:store_id].to_i) || not_found
  end


  def xls_content_for(objs,records,store_id)
    dir_path = Constant::LOCAL_DIR + "check_tables"
    Dir.mkdir(dir_path)  unless File.directory?(dir_path)
    Spreadsheet.client_encoding = "UTF-8"
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet :name => "库存物料核对表"
    sheet1.row(0).concat %w{名称 条形码 类别 规格 库存量 盘点数 盘点状态  差异数 备注}
    objs.each_with_index do |obj,index|
      s_c = records["#{obj.id}"]
      if s_c["storage"].to_i > s_c["check_num"].to_i
        status = "少于"
        num = s_c["storage"].to_i - s_c["check_num"].to_i
      elsif s_c["storage"].to_i < s_c["check_num"].to_i
        status = "多于"
        num = s_c["check_num"].to_i - s_c["storage"].to_i
      else
        status = "相同"
        num = 0
      end
      sheet1.row(index+1).concat ["#{obj.name}","#{obj.code}", "#{obj.cname}","#{obj.unit}",
        "#{s_c["storage"]}","#{s_c["check_num"]}","#{status}","#{num}","#{obj.remark}"]
    end
    sheet1.row(objs.length+1).concat ["物料数量", "#{objs.length}"]
    book.write dir_path+"/#{Time.now.strftime('%Y-%m-%d')}-#{store_id}.xls"
    "/check_tables/#{Time.now.strftime('%Y-%m-%d')}-#{store_id}.xls"
  end
end
