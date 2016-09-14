#encoding:utf-8
class SuppliersController < ApplicationController
  layout "storage"
  require "toPinyin"
  before_filter :sign?
  before_filter :find_store
  before_filter :find_supplier, :only => [:edit, :update, :destroy]
  require 'will_paginate/array'

  def index
    @types = Category.where(["types = ? and store_id = ?", Category::TYPES[:material], @store.id])
    sql = "s.store_id=#{params[:store_id]} and s.status=#{Supplier::STATUS[:normal]}"
    if params[:p_name] and params[:p_name] != "" and params[:p_name].length >0
      sql += " and s.name like '%#{params[:p_name].strip.gsub(/[%_]/){|x| '\\' + x}}%'"
    end
    @suppliers = Supplier.all(:select => "*", :from => "suppliers s",:conditions =>sql )
    @supps = @suppliers.paginate(:per_page => Constant::PER_PAGE, :page => params[:page])
    respond_to do |f|
      f.html
      f.js
    end
  end

  def new
    @supplier = Supplier.new
  end

  def create
    @supplier = Supplier.create(params[:supplier])
    if @supplier.save
      @store.suppliers << @supplier
      flash[:notice] = "供应商创建成功"
      render :success
    else
      flash[:notice] = "供应商创建失败"
      render :new
    end
  end

  def edit
  end

  def update
    name = params[:edit_supplier_name].strip
    contact = params[:edit_supplier_contact].strip
    phone = params[:edit_supplier_phone].strip
    email = params[:edit_supplier_email].strip
    addr = params[:edit_supplier_addr].strip
    cap_name = params[:cap_name].strip
    check_type = params[:edit_supplier_check_type].to_i
    check_time = check_type==1 ? params[:edit_supplier_check_time].to_i : nil
    if @supplier.update_attributes(:name => name, :contact => contact, :phone => phone, :email => email, :address => addr,
        :check_type => check_type, :check_time => check_time,:cap_name=>cap_name)
      flash[:notice] = "供应商编辑成功"
      render :success
    else
      flash[:notice] = "供应商编辑失败"
      render :edit
    end
  end

  def destroy
    @supplier.update_attribute(:status,Supplier::STATUS[:delete]) if @supplier && @supplier.status != Supplier::STATUS[:delete]
    flash[:notice] = "供应商删除成功"
    redirect_to store_suppliers_path @store
  end


  def check
    suppliers = Supplier.where(:store_id=>params[:store_id]).map(&:cap_name).compact
    cap_name = params[:name].split(" ").join("").split("").compact.map{|n|n.pinyin[0][0] if n.pinyin[0]}.compact.join("")
    msg_type = 0
    msg_type =1   if suppliers.include? cap_name
    render :json=>{:msg_type=>msg_type,:cap_name=>cap_name}
  end
  
  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end

  def find_supplier
    @supplier = Supplier.find_by_id(params[:id]) || not_found
  end

end