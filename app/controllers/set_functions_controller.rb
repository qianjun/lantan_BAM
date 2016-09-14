#encoding: utf-8
class SetFunctionsController < ApplicationController
  layout "role"
  before_filter :sign?
  def index
    @init = params[:init]
    @store = Store.find_by_id(params[:store_id].to_i)
    @departs = Department.where(["types = ? and store_id = ? and status = ?", Department::TYPES[:DEPARTMENT], #部门
        @store.id, Department::STATUS[:NORMAL]]).order("dpt_lv asc").group_by { |d| d.dpt_lv } if @init.nil? || @init.eql?("depart_init") || @init.eql?("set_positions")
    @positions = Department.where(["types = ? and store_id = ? and status = ? and dpt_id is not null",  #职务
        Department::TYPES[:POSITION], @store.id, Department::STATUS[:NORMAL]]).group_by { |p| p.dpt_id } if @init.nil? || @init.eql?("depart_init") || @init.eql?("set_positions")
    @market_servs = Category.where(["types= ? and store_id = ?", #营销中的服务
        Category::TYPES[:service], params[:store_id].to_i]) if @init.nil? || @init.eql?("market_init")
    @market_goods = Category.where(["types= ? and store_id = ?",  #营销中的产品
        Category::TYPES[:good], params[:store_id].to_i]) if @init.nil? || @init.eql?("market_init")
    @storage_goods = Category.where(["types= ? and store_id = ?",  #库存中的物料
        Category::TYPES[:material], params[:store_id].to_i]) if @init.nil? || @init.eql?("storage_init")
    respond_to do |f|
      f.html
      f.js
    end
  end

  def market_new    #营销-新建产品/服务
    @store_id = params[:store_id]
    @types = params[:types].to_i
  end

  def market_new_commit  #营销-新建产品/服务 提交
    types = params[:types]
    store_id = params[:store_id]
    name = params[:name]
    c = Category.where(["types = ? and store_id = ? and name = ?", types, store_id, name])
    if c.blank?
      if Category.create(:name => name, :types => types, :store_id => store_id)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def market_edit    #营销-编辑产品/服务
    @category = Category.find_by_id(params[:market_id].to_i)
  end

  def market_edit_commit  #营销-编辑产品/服务 提交
    category = Category.find_by_id(params[:market_id].to_i)
    name = params[:name]
    c = Category.where(["id != ? and types = ? and store_id = ? and name = ?",
        category.id, category.types, category.store_id, name])
    if c.blank?
      if category.update_attribute("name", name)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def storage_new   #库存-新建物料类别
    @store_id = params[:store_id].to_i
  end

  def storage_new_commit  #库存-新建物料类别 提交
    name = params[:name]
    store_id = params[:store_id].to_i
    c = Category.where(["store_id = ? and types = ? and name = ?", store_id, Category::TYPES[:material], name])
    if c.blank?
      if Category.create(:store_id => store_id, :types => Category::TYPES[:material], :name => name)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def storage_edit    #库存-编辑物料类别
    @category = Category.find_by_id(params[:storage_id].to_i)
  end

  def storage_edit_commit    #库存-编辑物料类别 提交   
    name = params[:name]
    store_id = params[:store_id].to_i
    c = Category.where(["id != ? and types = ? and store_id = ? and name = ?", params[:storage_id].to_i,
        Category::TYPES[:material], store_id, name])
    if c.blank?
      category = Category.find_by_id(params[:storage_id].to_i)
      if category.update_attribute("name", name)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def depart_new    #组织架构-新建部门
    @store_id = params[:store_id].to_i
  end

  def depart_new_commit   #组织架构-新建部门 提交
    name = params[:name]
    store_id = params[:store_id].to_i
    max_lv = Department.where(["store_id = ? and types = ? ", store_id, Department::TYPES[:DEPARTMENT]]).maximum("dpt_lv")
    d = Department.where(["store_id = ? and name = ? and status = ? and types = ? ", store_id, name,
        Department::STATUS[:NORMAL], Department::TYPES[:DEPARTMENT]])
    dpt_lv =  max_lv.nil? ? 1 : max_lv + 1
    if d.blank?
      if Department.create(:name => name, :types => Department::TYPES[:DEPARTMENT], :status => Department::STATUS[:NORMAL],
          :dpt_lv => dpt_lv, :store_id => store_id)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def sibling_depart_new  #组织架构-新建同级部门
    @store_id = params[:store_id].to_i
    @lv = params[:lv].to_i
  end

  def sibling_depart_new_commit #组织架构-新建同级部门 提交
    name = params[:name]
    lv = params[:lv].to_i
    store_id = params[:store_id].to_i
    d = Department.where(["store_id = ? and name = ? and status = ? and types = ? ", store_id, name,
        Department::STATUS[:NORMAL], Department::TYPES[:DEPARTMENT]])
    if d.blank?
      if Department.create(:name => name, :types => Department::TYPES[:DEPARTMENT], :status => Department::STATUS[:NORMAL],
          :dpt_lv => lv, :store_id => store_id)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def depart_edit  #组织架构-编辑部门
    @store_id = params[:store_id].to_i
    @depart = Department.find_by_id(params[:depart_id].to_i)
    @positions = Department.where(["types = ? and store_id = ? and status = ? and dpt_id = ?", Department::TYPES[:POSITION],
        @store_id, Department::STATUS[:NORMAL], @depart.id])

  end

  def depart_edit_commit    #组织架构-编辑部门 提交
    name = params[:name]
    did = params[:did].to_i
    store_id = params[:store_id].to_i
    d = Department.where(["id != ? and types = ? and status = ? and store_id =? and name = ?", did,
        Department::TYPES[:DEPARTMENT], Department::STATUS[:NORMAL], store_id, name])
    if d.blank?
      department = Department.find_by_id(did)
      if department.update_attribute("name", name)
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def depart_del    #组织架构-删除部门
    depart = Department.find_by_id(params[:did].to_i)
    depart.update_attribute("status", Department::STATUS[:DELETED])
    positions = Department.where(["types = ? and status = ? and dpt_id = ?", Department::TYPES[:POSITION],
        Department::STATUS[:NORMAL], depart.id])
    positions.each do |p|
      p.update_attribute("status", Department::STATUS[:DELETED])
    end
      render :json => {:status => 1}
  end

  def position_new  #组织架构-新建职务
    @dpt_id = params[:dpt_id].to_i
    @store_id = params[:store_id].to_i
  end

  def position_new_commit  #组织架构-新建职务 提交
    dpt_id = params[:dpt_id].to_i
    name = params[:name]
    store_id = params[:store_id].to_i
    p = Department.where(["types = ? and dpt_id = ? and status = ? and name = ?", Department::TYPES[:POSITION],
        dpt_id, Department::STATUS[:NORMAL], name])
    if p.blank?
      if Department.create(:name => name, :types => Department::TYPES[:POSITION], :dpt_id => dpt_id,
          :store_id => store_id, :status => Department::STATUS[:NORMAL])
        render :json => {:status => 1}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def position_edit_commit  #组织架构-编辑职务 提交
    pid = params[:pid].to_i
    name = params[:name]
    position = Department.find_by_id(pid)
    p = Department.where(["id != ? and types = ? and dpt_id = ? and status = ? and name = ?", pid, position.types,
        position.dpt_id, Department::STATUS[:NORMAL], name])
    if p.blank?
      if position.update_attribute("name", name)
        render :json => {:status => 1, :depart_id => position.dpt_id}
      else
        render :json => {:status => 0}
      end
    else
      render :json => {:status => 2}
    end
  end

  def position_del_commit #组织架构-删除职务
    position = Department.find_by_id(params[:pid].to_i)
    if position.update_attribute("status", Department::STATUS[:DELETED])
      render :json => {:status => 1, :depart_id => position.dpt_id}
    else
      render :json => {:status => 0}
    end
  end
end