#encoding: utf-8
class SalesController < ApplicationController    #营销管理 -- 活动
  before_filter :sign?
  layout 'sale'
  require "toPinyin"
  
  #活动列表
  def index
    @sales=Sale.paginate_by_sql("select s.id,name,s.store_id,s.started_at,s.everycar_times,s.disc_time_types,s.ended_at,s.code,s.status,on_weixin
    from sales s where s.store_id=#{params[:store_id]} and s.status !=#{Sale::STATUS[:DESTROY]} order by s.created_at desc ", :page => params[:page], :per_page => Constant::PER_PAGE)
    @orders = Order.select("sale_id,count(id) num").where(:store_id=>params[:store_id],:status=>[Order::STATUS[:BEEN_PAYMENT],Order::STATUS[:FINISHED]]).
      where("sale_id is not null").group("sale_id").inject(Hash.new){|hash,s|hash[s.sale_id]=s.num;hash}
  end

  #
  def new
    @sale=Sale.new
    @cats = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good],Category::TYPES[:service]]).inject(Hash.new){
      |hash,cate| hash[cate.id]=cate.name;hash}
  end

  #创建发布活动
  def create
    pams={:name=>params[:name],:status=>Sale::STATUS[:UN_RELEASE],:car_num=>params[:car_num],:everycar_times=>params[:every_car],
      :created_at=>Time.now,:introduction=>params[:intro],:discount=>params["disc_"+params[:discount]],
      :store_id=>params[:store_id], :disc_types=>params[:discount],:disc_time_types=>params[:disc_time],
      :code=>Sale.set_code(8,"sale","code"),:is_subsidy =>params[:subsidy]
    }
    pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})  if params[:disc_time].to_i == Sale::DISC_TIME[:TIME]
    pams.merge!({:sub_content=>params[:sub_content]}) if params[:subsidy].to_i == Sale::SUBSIDY[:YES]
    sale=Sale.create!(pams)
    flash[:notice] = "活动添加成功"
    #    begin
    if params[:img_url]
      filename = upload_stream(params[:img_url],[Constant::SALE_PICS,sale.store_id,sale.id],Constant::SALE_PICSIZE)
      sale.update_attributes(:img_url=>filename)
    end
    #    rescue
    #      flash[:notice] ="图片上传失败，请重新添加！"
    #    end
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>sale.id,:product_id=>key,:prod_num=>value})
    end
    redirect_to "/stores/#{params[:store_id]}/sales"
  end

  #编辑发布活动
  def edit
    @sale=Sale.find(params[:id])
    @cats = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good],Category::TYPES[:service]]).inject(Hash.new){
      |hash,cate| hash[cate.id]=cate.name;hash}
    @sale_prods=SaleProdRelation.find_by_sql("select p.name,s.prod_num num,p.id from sale_prod_relations s inner join 
    products p on s.product_id=p.id where s.sale_id=#{params[:id]}")
  end

  #加载产品或服务类别
  def load_types
    sql = "select id,name from products where  store_id=#{params[:store_id]} and status=#{Product::IS_VALIDATE[:YES]}"
    sql += " and category_id=#{params[:sale_types]}" if params[:sale_types] != "" || params[:sale_types].length !=0
    sql += " and name like '%#{params[:sale_name]}%'" if params[:sale_name] != "" || params[:sale_name].length !=0
    @products=Product.find_by_sql(sql)
  end

  #删除活动
  def delete_sale
    Sale.find(params[:ids]).each{|sale|sale.update_attributes(:status=>Sale::STATUS[:DESTROY])}
    render :json=>{:msg=>"删除成功"}
  end
  
  #更新活动
  def update_sale
    @sale=Sale.find(params[:id])
    pams={:name=>params[:name],:car_num=>params[:car_num],:everycar_times=>params[:every_car], :introduction=>params[:intro],
      :discount=>params["disc_"+params[:discount]],:is_subsidy =>params[:subsidy], :disc_types=>params[:discount],:disc_time_types=>params[:disc_time]
    }
    flash[:notice] = "活动更新成功"
    #    begin
    pams.merge!({:img_url=>upload_stream(params[:img_url],[Constant::SALE_PICS,@sale.store_id,@sale.id],Constant::SALE_PICSIZE)}) if params[:img_url]
    #    rescue
    #      flash[:notice] ="图片上传失败，请重新添加！"
    #    end
    pams.merge!({:started_at=>params[:started_at],:ended_at=>params[:ended_at]})  if params[:disc_time].to_i == Sale::DISC_TIME[:TIME]
    pams.merge!({:sub_content=>params[:sub_content]}) if params[:subsidy].to_i == Sale::SUBSIDY[:YES]
    @sale.update_attributes(pams)
    @sale.sale_prod_relations.inject(Array.new) {|arr,sale_prod| sale_prod.destroy}
    params[:sale_prod].each do |key,value|
      SaleProdRelation.create({:sale_id=>@sale.id,:product_id=>key,:prod_num=>value})
    end
    redirect_to "/stores/#{params[:store_id]}/sales"
  end

  #发布活动
  def public_sale
    Sale.find(params[:sale_id]).update_attributes(:status=>Sale::STATUS[:RELEASE])
    respond_to do |format|
      format.json {
        render :json=>{:message=>"发布成功"}
      }
    end
  end

  #活动详细页
  def show
    @sale=Sale.find(params[:id])
  end
  
  def upload_stream(img_url,dirs,img_code=nil)
    path = Constant::LOCAL_DIR + dirs.join("/")
    FileUtils.remove_dir path if  File.directory? path
    FileUtils.mkdir_p  path unless  File.directory? path
    filename = img_url.original_filename.split(".")
    dirs << "#{filename[0].pinyin.push(dirs[2]).join("")}."+ filename.reverse[0]
    path = Constant::LOCAL_DIR + dirs.join("/")
    File.open(path, "wb")  {|f|f.write(img_url.read)}
    return "/"+dirs.join("/")
  end
end
