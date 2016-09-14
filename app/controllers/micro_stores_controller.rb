#encoding: utf-8
class MicroStoresController < ApplicationController
  layout 'sale'

  def index
    @recommand_prods = (Store.find(params[:store_id]).recommand_prods ||= "").split(",")
    @product_serv = Product.on_weixin(params[:store_id]).group_by{|i|i.is_service}
    @card = (SvCard.on_weixin(params[:store_id]).select("name,types") << PackageCard.on_weixin(params[:store_id]).select("name,2 types")).flatten.group_by{|i|i.types}
  end

  #创建新品推荐
  def create
    begin
      status = 0
      Store.update(params[:store_id],recommand_prods: params[:recommand_ids])
    rescue
      status = 1
    end
    render :json=>{:status => status}
  end

  def upload_content
    @knows = KnowledgeType.import_types(params[:store_id])
    @knowledges = Knowlege.where(:store_id=>params[:store_id])
    @knowledges = nil if @knowledges.blank?
  end

  #更新宣传推广的类别
  def update
    begin
      status = 0
      KnowledgeType.update(params[:id],name: params[:name])
    rescue
      status = 1
    end
    render :json=>{:status => status,:id=>params[:id],:name=>params[:name]}
  end

  def create_know

    begin
      knowledge = Knowlege.create(params[:create_know].merge(:store_id=>params[:store_id]))
      knowledge.update_attributes({:img_url=>Sale.upload_img(params[:upload_img_file],knowledge,Constant::MICRO_STORE << "micro_stores")})  if params[:upload_img_file]
      flash[:notice] = "创建成功"
    rescue
      flash[:notice] = "创建失败"
    end
    redirect_to upload_content_store_micro_stores_path(params[:store_id])
  end

  def edit
    @know = Knowlege.find params[:id]
  end

  def edit_know
    begin
      knowledge = Knowlege.find(params[:id]).update_attributes(params[:create_know])
      if params[:upload_img_file] && params[:upload_img_file] != ""
        knowledge.update_attributes({:img_url=>Sale.upload_img(params[:upload_img_file],knowledge,Constant::MICRO_STORE << "micro_stores")})
      end
      flash[:notice] = "创建成功"
    rescue
      flash[:notice] = "创建失败"
    end
    redirect_to upload_content_store_micro_stores_path(params[:store_id])
  end

  def destroy
    begin
      status = 0
      Knowlege.delete_all(:id=>params[:id])
      status = 0
    rescue
      status = 1
    end
    render :json => {:status => status,:store=>params[:store_id]}
  end


end