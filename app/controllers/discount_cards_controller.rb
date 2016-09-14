#encoding: utf-8
class DiscountCardsController < ApplicationController   #打折卡
  require 'will_paginate/array'
  layout "sale"
  before_filter :get_store

  def index
    @types = Category.where(["store_id = ? and types in (?)", @store.id, [Category::TYPES[:good], Category::TYPES[:service]]])
    @sv_cards = SvCard.where(["store_id = ? and status = ? and types = ? ",  @store.id, SvCard::STATUS[:NORMAL],
        SvCard::FAVOR[:DISCOUNT]]).order("created_at desc").paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
  end

  def create
    name = params[:dcard_name]
    use_range = params[:dcard_userange]
    price = params[:dcard_price]
    products = params[:dcard_products]
    img = params[:dcard_img]
    desc = params[:dcard_description]
    s = SvCard.where(["types = ? and name = ? and status = ? and store_id = ?",SvCard::FAVOR[:DISCOUNT], name,
        SvCard::STATUS[:NORMAL], @store.id])
    if s.blank?
      dcard = SvCard.new(:name => name, :types => SvCard::FAVOR[:DISCOUNT], :price => price, :description => desc,
        :store_id => @store.id, :use_range => use_range, :status => SvCard::STATUS[:NORMAL])
      if dcard.save
        products.each do |p|
          pid = p.split("-")[0].to_i
          pdiscount = p.split("-")[1].to_f
          SvcardProdRelation.create(:product_id => pid, :sv_card_id => dcard.id, :product_discount => pdiscount*10)
        end
        if img
          begin
            url = SvCard.upload_img(img, dcard.id, Constant::SVCARD_PICS, @store.id, Constant::SVCARD_PICSIZE)
            dcard.update_attribute("img_url", url)
            flash[:notice] = "新建成功!"
          rescue
            flash[:notice] = "图片上传失败!"
          end
        else
          flash[:notice] = "新建成功!"         
        end
        redirect_to "/stores/#{@store.id}/discount_cards"
      else
        flsh[:notice] = "新建失败"
        redirect_to request.referer
      end          
    else
      flash[:notice] = "新建失败，已存在同名的打折卡!"
      redirect_to request.referer
    end
  end


  def add_products_search   #新建优惠卡 添加产品或服务 查询
    type = params[:type]
    name = params[:name]
    @arr = params[:arr] if !params[:arr].nil? || !params[:arr].blank?
    sql = ["select p.id pid, p.name pname from products p inner join categories c
           on p.category_id = c.id where c.types in (?) and c.store_id = ? and p.status = ?",
      [Category::TYPES[:good], Category::TYPES[:service]], @store.id, Product::IS_VALIDATE[:YES]]
    unless type.to_i == 0
      sql[0] += " and c.id = ?"
      sql << type
    end
    unless name.nil? || name.empty?
      sql[0] += " and p.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"     
    end
    @products = Product.find_by_sql(sql)
  end

  def edit  #编辑
    cid = params[:cid].to_i
    @dcard = SvCard.find_by_id(cid)
    @products = Product.find_by_sql(["select p.id pid, p.name pname, spr.product_discount discount from sv_cards sc
                                      inner join svcard_prod_relations spr on spr.sv_card_id=sc.id
                                      inner join products p on p.id=spr.product_id where sc.id=?
                                      and p.status=?", cid, Product::IS_VALIDATE[:YES]])
  end

  def update
    name = params[:edit_dcard_name]
    use_range = params[:edit_dcard_userange]
    price = params[:edit_dcard_price]
    products = params[:edit_dcard_products]
    img = params[:edit_dcard_img]
    desc = params[:edit_dcard_description]
    id = params[:id]
    s = SvCard.where(["id != ? and types = ? and name = ? and status = ? and store_id = ?", id,
        SvCard::FAVOR[:DISCOUNT], name, SvCard::STATUS[:NORMAL], @store.id])
    if s.blank?
      dcard = SvCard.find_by_id(id)
      if dcard.update_attributes(:name => name, :price => price, :description => desc,
          :use_range => use_range)
        SvcardProdRelation.delete_all(:sv_card_id => dcard.id)
        products.each do |p|
          pid = p.split("-")[0].to_i
          pdiscount = p.split("-")[1].to_f
          SvcardProdRelation.create(:product_id => pid, :sv_card_id => dcard.id, :product_discount => pdiscount*10)
        end
        if img
          begin
            url = SvCard.upload_img(img, dcard.id, Constant::SVCARD_PICS, @store.id, Constant::SVCARD_PICSIZE)
            dcard.update_attribute("img_url", url)
            flash[:notice] = "编辑成功!"
          rescue
            flash[:notice] = "图片上传失败!"
          end
        else
          flash[:notice] = "编辑成功!"
        end
      end
    else
      flash[:notice] = "编辑失败，已存在同名的打折卡!"
    end
    redirect_to request.referer
  end

#  def destroy
#    dcard = SvCard.find_by_id(params[:id])
#    if dcard.update_attribute("status", SvCard::STATUS[:DELETED])
#      flash[:notice] = "删除成功!"
#      redirect_to store_discount_cards_path
#    else
#      flash[:notice] = "删除失败!"
#      redirect_to request.referer
#    end
#  end

  def edit_dcard_add_products #编辑 添加项目
    cid = params[:cid].to_i
    @types = Category.where(["store_id = ? and types in (?)", @store.id, [Category::TYPES[:good], Category::TYPES[:service]]])
    @products = Product.find_by_sql(["select p.id pid, p.name pname, spr.product_discount discount
                                      from svcard_prod_relations spr inner join products p
                                      on spr.product_id=p.id where spr.sv_card_id=?", cid])
    
  end

  def edit_add_products_search   #编辑优惠卡 添加产品或服务 查询
    type = params[:type]
    name = params[:name]
    @arr = params[:arr] if !params[:arr].nil? || !params[:arr].blank?
    sql = ["select p.id pid, p.name pname from products p inner join categories c
           on p.category_id = c.id where c.types in (?) and c.store_id = ? and p.status = ?",
      [Category::TYPES[:good], Category::TYPES[:service]], @store.id, Product::IS_VALIDATE[:YES]]
    unless type.to_i == 0
      sql[0] += " and c.id = ?"
      sql << type
    end
    unless name.nil? || name.empty?
      sql[0] += " and p.name like ?"
      sql << "%#{name.strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
    @products = Product.find_by_sql(sql)
  end

  def del_all_dcards    #批量删除打折卡
    a = params[:ids]
    SvCard.where(:id=>a).update_all(:status => SvCard::STATUS[:DELETED])
    render :json => 0
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end
