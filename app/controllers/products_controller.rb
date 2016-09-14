#encoding: utf-8
class ProductsController < ApplicationController
  before_filter :sign?
  # 营销管理 -- 产品
  layout 'sale'

  def index
    sql = ["select service_code code,p.name,sale_price,t_price,base_price,p.id,p.store_id,prod_point,c.name c_name,on_weixin
    from products p inner join categories c on p.category_id=c.id where c.store_id=#{params[:store_id]} and p.status=#{Product::IS_VALIDATE[:YES]}
    and c.types=#{Category::TYPES[:good]}"]
    count_sql = "categories.store_id=#{params[:store_id]} and products.status=#{Product::IS_VALIDATE[:YES]} and
    categories.types=#{Category::TYPES[:good]}"
    unless params[:p_name].nil? || params[:p_name].strip == ""
      p_name =  "%#{params[:p_name].strip.gsub(/[%_]/){|x|'\\' + x}}%"
      sql[0] += " and p.name like ?"
      sql << p_name
      count_sql += " and products.name like '#{p_name}'"
    end
    sql[0] += "  order by p.created_at desc"
    @products = Product.paginate_by_sql(sql, :page => params[:page], :per_page =>Constant::PER_PAGE)
    @total = Product.joins(:category).where(count_sql).select("count(*) num").first
  end  #产品列表页

  #新建产品
  def add_prod
    @product=Product.new
    @cates = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good],Category::TYPES[:material]]).inject(Hash.new){
      |hash,ca| hash[ca.types].nil? ? hash[ca.types] = {ca.id => ca.name}:hash[ca.types][ca.id]=ca.name;hash}
    @materials = Material.where(:store_id=>params[:store_id],:status =>Material::STATUS[:NORMAL]).where("category_id is not null").order(:category_id)
    @max_len = check_str(@materials.map(&:name)[0])
    @materials.map(&:name).each{|name| @max_len = check_str(name) if check_str(name) >= @max_len}
  end
  
  def create
    set_product(Constant::PRODUCT)
    redirect_to "/stores/#{params[:store_id]}/products"
  end  #添加产品


  def prod_services
    @services = Product.paginate_by_sql("select p.id, service_code code,prod_point,p.store_id,p.name,base_price,cost_time,t_price,sale_price,
    staff_level level1,staff_level_1 level2,commonly_used,c.name c_name,on_weixin from products p inner join categories c on c.id=p.category_id where c.store_id=#{params[:store_id]}
    and c.types=#{Category::TYPES[:service]} and p.status=#{Product::IS_VALIDATE[:YES]} and p.single_types=#{Product::SINGLE_TYPE[:SIN]}
    order by p.created_at desc", :page => params[:page], :per_page => Constant::PER_PAGE)
    @total = Product.joins(:category).where("categories.store_id=#{params[:store_id]} and categories.types=#{Category::TYPES[:service]}
    and  products.status=#{Product::IS_VALIDATE[:YES]} and  products.single_types=#{Product::SINGLE_TYPE[:SIN]}").select("count(*) num").first
    @materials = @services.blank? ? {} : Material.find_by_sql("select name,code,p.material_num num,product_id from materials m inner join
    prod_mat_relations p on  p.material_id=m.id  where p.product_id in (#{@services.map(&:id).join(',')})").inject(Hash.new){|hash,mat|
      hash[mat.product_id].nil? ? hash[mat.product_id] = [mat] : hash[mat.product_id] << mat;hash}
  end   #服务列表

  def serv_create
    set_product(Constant::SERVICE)
    redirect_to "/stores/#{params[:store_id]}/products/prod_services"
  end   #添加服务

  def set_product(types)
    flash[:notice] = "添加成功"
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:intro],
      :category_id=>params[:prod_types],:status=>Product::IS_VALIDATE[:YES],:introduction=>params[:desc], :store_id=>params[:store_id],:t_price=>params[:t_price],
      :is_service=>Product::PROD_TYPES[:"#{types}"],:created_at=>Time.now.strftime("%Y-%M-%d"), :service_code=>"#{types[0]}#{Sale.set_code(3,"product","service_code")}",
      :is_auto_revist=>params[:auto_revist],:auto_time=>params[:time_revist],:revist_content=>params[:con_revist],:prod_point=>params[:prod_point]=="" ? 0 : params[:prod_point]}
    parms.merge!(:deduct_price=>params[:deduct_price].nil? ? 0 : params[:deduct_price],:techin_price=>params[:techin_price].nil? ? 0 :params[:techin_price] )
    parms.merge!(:deduct_percent=>params[:deduct_percent].nil? ? 0 : params[:deduct_percent].to_f*params[:sale_price].to_f/100)
    parms.merge!({:techin_percent=>params[:techin_percent].nil? ? 0 : params[:techin_percent].to_f*params[:sale_price].to_f/100})
    if types == Constant::SERVICE
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2],
          :single_types=>Product::SINGLE_TYPE[:SIN]})
      product =Product.create(parms)
      params[:sale_prod].each do |key,value|
        ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
      end if params[:sale_prod]
    else
      added = params[:is_added].nil? ? 0 : params[:is_added]
      flash[:notice] = "产品重复"  if Product.where(:status => Product::IS_VALIDATE[:YES]).map(&:name).include? params[:name]
      parms.merge!({:standard=>params[:standard],:is_added =>added})
      product =Product.create(parms)
      ProdMatRelation.create(:product_id=>product.id,:material_num=>1,:material_id=>params[:prod_material].to_i)
    end
    begin
      if params[:img_url] and !params[:img_url].keys.blank?
        image_urls = []
        params[:img_url].each {|k,img|
          image_urls <<  ImageUrl.new(:product_id=>product.id,
            :img_url=>Sale.upload_img(img,product,Constant::P_PICSIZE << "#{types.downcase}_pics",k))}
        ImageUrl.import image_urls
        product.update_attributes({:img_url=>image_urls[0].img_url})
      end
    rescue
      flash[:notice] ="图片上传失败，请重新添加！"
    end
  end   #为新建产品或者服务提供参数

  def edit_prod
    @product =Product.find(params[:id])
    @img_urls=@product.image_urls
    @cates = Category.where(:store_id=>params[:store_id],:types=>[Category::TYPES[:good],Category::TYPES[:material]]).inject(Hash.new){
      |hash,ca| hash[ca.types].nil? ? hash[ca.types] = {ca.id => ca.name}:hash[ca.types][ca.id]=ca.name;hash}
    @materials = Material.where(:store_id=>params[:store_id],:status =>Material::STATUS[:NORMAL]).where("category_id is not null").order(:category_id)
    @max_len = check_str(@materials.map(&:name)[0])
    @materials.map(&:name).each{|name| @max_len = check_str(name) if check_str(name) >= @max_len}
    @material = @product.prod_mat_relations[0]
  end

  def show_prod
    @product =Product.find(params[:id])
    @img_urls = @product.image_urls
  end

  def update_product(types,product)
    parms = {:name=>params[:name],:base_price=>params[:base_price],:sale_price=>params[:sale_price],:description=>params[:intro],
      :category_id=>params[:prod_types],:introduction=>params[:desc],:t_price=>params[:t_price], :is_auto_revist=>params[:auto_revist],
      :auto_time=>params[:time_revist],:revist_content=>params[:con_revist],:prod_point=>params[:prod_point]=="" ? 0 : params[:prod_point]}
    parms.merge!(:deduct_price=>params[:deduct_price].nil? ? 0 : params[:deduct_price],:techin_price=>params[:techin_price].nil? ? 0 :params[:techin_price] )
    parms.merge!(:deduct_percent=>params[:deduct_percent].nil? ? 0 : params[:deduct_percent].to_f*params[:sale_price].to_f/100)
    parms.merge!({:techin_percent=>params[:techin_percent].nil? ? 0 : params[:techin_percent].to_f*params[:sale_price].to_f/100})
    service,flash[:notice] = false,"更新成功"
    if types == Constant::SERVICE
      parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2] })
      service = true if [product.staff_level,product.staff_level_1].sort != [params[:level1].to_i,params[:level2].to_i].sort
      if params[:sale_prod]
        product.prod_mat_relations.inject(Array.new) {|arr,mat| mat.destroy}
        params[:sale_prod].each do |key,value|
          ProdMatRelation.create(:product_id=>product.id,:material_num=>value,:material_id=>key)
        end
      end
    else
      if product.prod_mat_relations.first
        product.prod_mat_relations.first.update_attributes(:material_id=>params[:prod_material].to_i)
      else
        ProdMatRelation.create(:product_id=>product.id,:material_num=>1,:material_id=>params[:prod_material].to_i)
      end
      added = params[:is_added].nil? ? 0 : params[:is_added]
      parms.merge!({:standard=>params[:standard],:is_auto_revist=>params[:auto_revist],:auto_time=>params[:time_revist],
          :revist_content=>params[:con_revist],:prod_point=>params[:prod_point],:is_added =>added})
      flash[:notice] = "产品重复"  if Product.where(:status => Product::IS_VALIDATE[:YES]).where("id != (?)",product.id).map(&:name).include? params[:name]
    end
    begin
      if params[:img_url] and !params[:img_url].keys.blank?
        ImageUrl.delete_all(:product_id => product.id)
        image_urls = []
        params[:img_url].each {|k,img|image_urls << ImageUrl.new(:product_id=>product.id,
            :img_url=>Sale.upload_img(img,product,Constant::P_PICSIZE << "#{types.downcase}_pics",k))}
        ImageUrl.import image_urls
        product.update_attributes({:img_url=>image_urls[0].img_url})
      end
    rescue
      flash[:notice] ="图片上传失败，请重新添加图片！"
    end
    product.update_attributes(parms)
    product.alter_level if service
  end

  def update_prod
    update_product(Constant::PRODUCT,Product.find(params[:id]))
    redirect_to request.referer
  end

  def show_serv
    @serv=Product.find(params[:id])
    @mats= Material.find_by_sql("select name from materials m inner join prod_mat_relations p on
        p.material_id=m.id  where p.product_id=#{@serv.id}").map(&:name).join("  ")
    @img_urls = @serv.image_urls
  end

  def add_serv
    @service=Product.new
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:service])
    @search_cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:material]).inject(Hash.new){
      |hash,cate| hash[cate.id]=cate.name;hash}
  end

  def edit_serv
    @service=Product.find(params[:id])
    @sale_prods =ProdMatRelation.find_by_sql("select m.name,s.material_num num,m.id from materials m inner join prod_mat_relations s on s.material_id=m.id
      where s.product_id=#{params[:id]}")
    @img_urls = @service.image_urls
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:service])
    @search_cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:material]).inject(Hash.new){
      |hash,cate| hash[cate.id]=cate.name;hash}
  end

  def serv_update
    update_product(Constant::SERVICE,Product.find(params[:id]))
    redirect_to request.referer
  end

  #加载物料信息
  def load_material
    sql = "select id,name from materials  where  store_id=#{params[:store_id]} and status=#{Material::STATUS[:NORMAL]}"
    sql += " and category_id=#{params[:mat_types]}" if params[:mat_types] != "" || params[:mat_types].length !=0
    sql += " and name like '%#{params[:mat_name]}%'" if params[:mat_name] != "" || params[:mat_name].length !=0
    @materials=Material.find_by_sql(sql)
  end

  def show
    @prod = Product.find(params[:id])
    @category = Category.find(@prod.category_id).name if @prod.category_id
    @img_urls = @prod.image_urls
  end

  def destroy_prod
    Product.where(:id=>params[:ids]).update_all(:status=>Product::IS_VALIDATE[:NO])
    Product.find(params[:ids]).each do |prod|
      if prod.is_service
        prod.alter_level
      else
        Material.where(:id=>ProdMatRelation.find_by_product_id(prod.id).material_id).update_all(:create_prod=>0)
      end
    end
    render :json=>{:msg=>"删除成功"}
  end


  def update_status
    vals =JSON params[:vals]
    Product.find(params[:ids].split(",")).each {|prod| prod.update_attributes(:show_on_ipad =>vals["#{prod.id}"]) if (prod.show_on_ipad ? 1 : 0) != vals["#{prod.id}"]}
    flash[:notice] = "更新成功"
    redirect_to request.referer
  end

  #服务作为常用显示在new app上面
  def commonly_used
    #store_id, id
    @service = Product.find_by_id(params[:id])
    if @service
      if @service.commonly_used
        @service.update_attribute(:commonly_used, false)
      else
        @service.update_attribute(:commonly_used, true)
      end
      @status = 1
      @notice = "操作成功"
    else
      @status = 0
      @notice = "服务未找到"
    end
  end

  def package_service
    @services = Product.paginate_by_sql("select p.id, service_code code,p.store_id,p.name,cost_time,staff_level level1,
    staff_level_1 level2,commonly_used from products p where p.store_id=#{params[:store_id]}
    and is_service=#{Product::PROD_TYPES[:SERVICE]} and status=#{Product::IS_VALIDATE[:YES]} and single_types=#{Product::SINGLE_TYPE[:DOUB]}
    order by p.created_at desc", :page => params[:page], :per_page => Constant::PER_PAGE)
    @total = Product.where(:store_id=>params[:store_id],:status=>Product::IS_VALIDATE[:YES],:single_types=>Product::SINGLE_TYPE[:DOUB]).select("count(*) num").first
  end

  def pack_create
    flash[:notice] = "添加成功"
    parms = {:name=>params[:name],:category_id=>Product::PACK[:PACK],:status=>Product::IS_VALIDATE[:YES],:is_service=>Product::PROD_TYPES[:SERVICE],
      :created_at=>Time.now.strftime("%Y-%M-%d"), :service_code=>"S#{Sale.set_code(3,"product","service_code")}",:is_auto_revist=>params[:auto_revist],
      :auto_time=>params[:time_revist],:store_id=>params[:store_id],:revist_content=>params[:con_revist],:single_types=>Product::SINGLE_TYPE[:DOUB]}
    parms.merge!(:techin_price=>params[:techin_price].nil? ? 0 :params[:techin_price] )
    parms.merge!({:techin_percent=>params[:techin_percent].nil? ? 0 : params[:techin_percent].to_f*params[:sale_price].to_f/100})
    parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2]})
    Product.create(parms)
    redirect_to request.referer
  end

  def add_package
    @package = Product.new
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:service])
  end

  def edit_pack
    @package = Product.find params[:id]
    @cates = Category.where(:store_id=>params[:store_id],:types=>Category::TYPES[:service])
  end

  def pack_update
    flash[:notice] = "更新成功"
    parms = {:name=>params[:name],:is_auto_revist=>params[:auto_revist],:auto_time=>params[:time_revist],:revist_content=>params[:con_revist]}
    parms.merge!(:techin_price=>params[:techin_price].nil? ? 0 :params[:techin_price] )
    parms.merge!({:techin_percent=>params[:techin_percent].nil? ? 0 : params[:techin_percent].to_f*params[:sale_price].to_f/100})
    parms.merge!({:cost_time=>params[:cost_time],:staff_level=>params[:level1],:staff_level_1=>params[:level2]})
    Product.find(params[:id]).update_attributes(parms)
    redirect_to request.referer
  end
end
