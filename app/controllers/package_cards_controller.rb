#encoding: utf-8
class PackageCardsController < ApplicationController
  before_filter :sign?
  # 营销管理 -- 套餐卡
  layout 'sale'
  require 'will_paginate/array'

  def index
    session[:pcard],session[:car_num],session[:c_name],session[:created_at],session[:ended_at]=nil,nil,nil,nil,nil
    @cards =PackageCard.paginate_by_sql("select name,img_url,started_at,prod_point,ended_at,id,date_types,date_month,on_weixin from package_cards where
    store_id=#{params[:store_id]} and status =#{PackageCard::STAT[:NORMAL]}", :page => params[:page], :per_page => Constant::PER_PAGE)
    unless @cards.blank?
      @prods,@materials = {},{}
      prods =Product.find_by_sql("select s.name,p.product_num num,package_card_id from products s inner join
    pcard_prod_relations p on s.id=p.product_id  where p.package_card_id in (#{@cards.map(&:id).join(",")})")
      prods.each {|prod| @prods[prod.package_card_id].nil? ? @prods[prod.package_card_id]=[prod] : @prods[prod.package_card_id] << prod }
      materials =Product.find_by_sql("select s.name,p.material_num num,package_card_id from materials s inner join
    pcard_material_relations p on s.id=p.material_id  where p.package_card_id in (#{@cards.map(&:id).join(",")})")
      materials.each {|prod| @materials[prod.package_card_id].nil? ? @materials[prod.package_card_id]=[prod] : @materials[prod.package_card_id] << prod }
    end
    @total = PackageCard.where("package_cards.store_id=#{params[:store_id]} and status=#{PackageCard::STAT[:NORMAL]}").select("count(*) num").first
  end #套餐卡列表
  
  def create
    PackageCard.transaction do
      parms = {:name=>params[:name], :store_id=>params[:store_id],:status=>PackageCard::STAT[:NORMAL], :price=>params[:price],
        :created_at=>Time.now.strftime("%Y-%M-%d"),:date_types =>params[:time_select],:is_auto_revist=>params[:auto_revist],
        :auto_time=>params[:time_revist], :revist_content=>params[:con_revist],:prod_point=>params[:prod_point],
        :description=>params[:desc],:auto_warn=>params[:auto_warn],:time_warn=>params[:time_warn],:con_warn=>params[:con_warn]}
      parms.merge!(:deduct_price=>params[:deduct_price].nil? ? 0 : params[:deduct_price])
      parms.merge!(:deduct_percent=>params[:deduct_percent].nil? ? 0 : params[:deduct_percent].to_f*params[:price].to_f/100)
      if params[:time_select].to_i == PackageCard::TIME_SELCTED[:PERIOD]
        parms.merge!(:started_at=>params[:started_at],:ended_at=>params[:ended_at].to_datetime.end_of_day.strftime("%Y-%m-%d %H:%M:%S"))
      else
        parms.merge!(:date_month =>params[:end_time])
      end
      prods = Product.where(:id=>params[:sale_prod].keys)
      total_price = prods.inject(0){|sum,p|sum+((p.sale_price.nil? ? 0 : p.sale_price)*params[:sale_prod]["#{p.id}"].to_i)}
      sale_percent  = total_price > params[:price].to_f ? params[:price].to_f/total_price : 1
      pcard =PackageCard.create( parms.merge!(:sale_percent=>sale_percent))
      flash[:notice] = "套餐卡添加成功"
      if params[:material_types] && params[:material_types] != ""  && params[:material_types].length != 0
        PcardMaterialRelation.create(:package_card_id=>pcard.id,:material_id=>params[:material_types],:material_num=>params[:material_num])
      end
      begin
        pcard.update_attributes(:img_url=>Sale.upload_img(params[:img_url],pcard,Constant::C_PICSIZE))  if params[:img_url]
      rescue
        flash[:notice] ="图片上传失败，请重新添加！"
      end
      params[:sale_prod].each do |key,value|
        PcardProdRelation.create(:package_card_id=>pcard.id,:product_id=>key,:product_num=>value)
      end
    end
    redirect_to request.referer
  end #添加套餐卡


  def sale_records
    @p_cards =PackageCard.search_pcard(params[:store_id])
    @cards= @p_cards.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @card_fee = @p_cards.inject(0) {|num,card| num+card.price }
    @pcards = @p_cards.inject(Array.new) {|p_hash,card| p_hash << [card.p_id,card.p_name];p_hash.uniq }
    #content中存放使用情况 将所有产品或服务以字符串组合存放，包含 产品id,name,剩余次数
  end #销售记录

  #加载产品或者服务类型
  def pcard_types
    sql = "select id,name,ifnull(sale_price,0) price from products where  store_id=#{params[:store_id]} and status=#{Product::IS_VALIDATE[:YES]}"
    sql += " and category_id=#{params[:sale_types]}" if params[:sale_types] != "" || params[:sale_types].length !=0
    sql += " and name like '%#{params[:sale_name]}%'" if params[:sale_name] != "" || params[:sale_name].length !=0
    @products = Product.find_by_sql(sql)
  end

  #添加套餐卡
  def add_pcard
    @pcard=PackageCard.new
    @cates = Category.where(:store_id=>params[:store_id]).inject(Hash.new){
      |hash,cate| hash[cate.types].nil? ?  hash[cate.types]={cate.id=>cate.name} :hash[cate.types][cate.id]=cate.name ;hash}
  end

  #编辑套餐卡
  def edit_pcard
    @pcard = PackageCard.find(params[:id])
    @sale_prods= Product.find_by_sql("select s.name,p.product_num num,s.id from products s inner join
     pcard_prod_relations p on s.id=p.product_id  where p.package_card_id=#{params[:id]}")
    @p_material = PcardMaterialRelation.find_by_package_card_id(@pcard.id)
    @material = Material.find(@p_material.material_id) if @p_material
    @cates = Category.where(:store_id=>params[:store_id]).inject(Hash.new){
      |hash,cate| hash[cate.types].nil? ?  hash[cate.types]={cate.id=>cate.name} :hash[cate.types][cate.id]=cate.name ;hash}
  end

  #更新套餐卡
  def update_pcard
    pcard=PackageCard.find(params[:id])
    parms = {:name=>params[:name],:date_types =>params[:time_select],:is_auto_revist=>params[:auto_revist],
      :auto_time=>params[:time_revist], :revist_content=>params[:con_revist],:prod_point=>params[:prod_point],
      :description=>params[:desc],:auto_warn=>params[:auto_warn],:time_warn=>params[:time_warn],:con_warn=>params[:con_warn]
    }
    parms.merge!(:deduct_price=>params[:deduct_price].nil? ? 0 : params[:deduct_price])
    parms.merge!(:deduct_percent=>params[:deduct_percent].nil? ? 0 : params[:deduct_percent].to_f*params[:price].to_f/100)
    if params[:time_select].to_i == PackageCard::TIME_SELCTED[:PERIOD]
      parms.merge!(:started_at=>params[:started_at],:ended_at=>params[:ended_at].to_datetime.end_of_day.strftime("%Y-%m-%d %H:%M:%S"))
    else
      parms.merge!(:date_month =>params[:end_time])
    end
    flash[:notice] = "套餐卡更新成功"
    begin
      parms.merge!(:img_url=>Sale.upload_img(params[:img_url],pcard,Constant::C_PICSIZE))  if params[:img_url]
    rescue
      flash[:notice] ="图片上传失败，请重新添加！"
    end
    pcard.update_attributes(parms)
    PcardMaterialRelation.delete(pcard.pcard_material_relations.map(&:id))
    if params[:material_types] && params[:material_types] != ""  && params[:material_types].length != 0
      PcardMaterialRelation.create(:package_card_id=>pcard.id,:material_id=>params[:material_types],:material_num=>params[:material_num])
    end
    #    pcard.pcard_prod_relations.inject(Array.new) {|arr,sale_prod| sale_prod.destroy}
    #    params[:sale_prod].each do |key,value|
    #      PcardProdRelation.create(:package_card_id=>pcard.id,:product_id=>key,:product_num=>value)
    #    end
    redirect_to request.referer
  end

  #删除活动
  def delete_pcard
    PackageCard.find(params[:ids]).each{|pcard| pcard.update_attributes(:status=>PackageCard::STAT[:INVALID])}
    render :json=>{:msg=>"删除成功"}
  end

  def search
    session[:pcard],session[:car_num],session[:c_name],session[:created_at],session[:ended_at]=nil,nil,nil,nil,nil
    session[:pcard],session[:car_num],session[:c_name]=params[:pcard],params[:car_num],params[:c_name]
    session[:created_at],session[:ended_at]=params[:created_at],params[:ended_at]
    redirect_to "/stores/#{params[:store_id]}/package_cards/search_list"
  end

  def search_list
    @p_cards =PackageCard.search_pcard(params[:store_id],session[:pcard],session[:car_num],session[:c_name],session[:created_at],session[:ended_at])
    @cards=@p_cards.paginate(:page=>params[:page],:per_page=>Constant::PER_PAGE)
    @card_fee = @p_cards.inject(0) {|num,card| num+card.price }
    @pcards = PackageCard.search_pcard(params[:store_id]).inject(Array.new) {|p_hash,card| p_hash << [card.p_id,card.p_name];p_hash.uniq }
    render "sale_records"
  end
  
  def request_material
    materials = Material.select("id,name").where(:store_id=>params[:store_id],:category_id=>params[:id]).
      where(:status=>Material::STATUS[:NORMAL]).inject(Hash.new){|hash,material|hash[material.id]=material.name;hash}
    render :json=>materials
  end

  #设置在微信上面显示的产品，服务，套餐卡和打折卡，储值卡等
  def on_weixin
    begin
      status =1
      obj = eval(params[:model]).find(params[:object_id])
      obj.toggle!(:on_weixin)
      on_weixin = obj.on_weixin
    rescue
      status = 0
      on_weixin = false
    end
    render :json=>{:status=>status,:change=>on_weixin}
  end
  
end
