#encoding: utf-8
class RolesController < ApplicationController
  require 'will_paginate/array'
  layout "role"
  before_filter :sign?
  before_filter :find_store

  #角色列表
  def index
    @roles = Role.find_all_by_store_id(params[:store_id].to_i)
    @role_id = params[:role_id] if params[:role_id]
    @menus = Menu.all
    @role_menu_relation_menu_ids = RoleMenuRelation.where(:role_id => @role_id).map(&:menu_id) if @role_id
    respond_to do |f|
      f.html
      f.js
    end
  end

  #修改角色名称
  def update
    role = Role.find_by_id_and_store_id params[:id], params[:store_id]
    status = 0
    if role
      role.update_attribute(:name, params[:name])
    else
      status = 1
    end
    render :json => {:status => status}
  end

  #添加角色
  def create
    role = Role.find_by_name_and_store_id(params[:name], params[:store_id].to_i)
    status = 0
    if role.nil?
      Role.create(:name => params[:name], :store_id => params[:store_id].to_i, :role_type => Role::ROLE_TYPE[:NORMAL])
    else
      status = 1
    end
    render :json => {:status => status}
  end

  #查询员工
  def staff
    str = ["store_id = ?", params[:store_id].to_i]
    if params[:name]
      str[0] += " and name like ?"
      str << "%#{params[:name].strip.gsub(/[%_]/){|x| '\\' + x}}%"
    end
#    @staffs = Staff.valid.joins(:staff_role_relations => :role).paginate(:conditions => str,
#      :page => params[:page], :per_page => Constant::PER_PAGE)
    @staffs = Staff.valid.where(str).paginate(:page => params[:page], :per_page => Constant::PER_PAGE)

    @roles = Role.where(:store_id =>params[:store_id].to_i).where("role_type = (?)",Role::ROLE_TYPE[:NORMAL])
    respond_to do |f|
      f.html
      f.js
    end
  end

  #角色功能设定
  def set_role
    if params[:role_id]
      role_id = params[:role_id]
      role = Role.find role_id
      if params[:menu_checks] #处理角色-菜单设置
        menus = Menu.where(:id => params[:menu_checks])
        role.menus = menus
      end
      if params[:model_nums] #处理角色-功能模块设置
        params[:model_nums].each do |controller, num|
          role_model_relation = RoleModelRelation.where(:role_id => role_id, :model_name => controller)
          if role_model_relation.empty?
            RoleModelRelation.create(:num => num.map(&:to_i).sum, :role_id => role_id, 
              :model_name => controller, :store_id => params[:store_id])
          else
            role_model_relation.first.update_attributes(:num => num.map(&:to_i).sum)
          end
        end
        deleted_menus = RoleModelRelation.where(:role_id => role_id).map(&:model_name) - params[:model_nums].keys
        RoleModelRelation.delete_all(:role_id => role_id, :model_name => deleted_menus) unless deleted_menus.empty?
      end
    end
    flash[:notice] = "设置成功!"
    redirect_to store_roles_url(params[:store_id])
  end

  #删除角色
  def destroy
    role = Role.find_by_id params[:id].to_i
    status = 0
    if role
      puts role.name
      Role.transaction do
        begin
          RoleMenuRelation.delete_all("role_id=#{role.id}")
          RoleModelRelation.delete_all("role_id=#{role.id}")
          StaffRoleRelation.delete_all("role_id=#{role.id}")
          role.destroy
          status = 1
        rescue
          status = 2
        end
      end

    end
    render :json => {:status => status}
  end

  #用户角色设定
  def reset_role
    staff = Staff.find_by_id params[:staff_id].to_i
    status = 0
    if staff
      StaffRoleRelation.delete_all("staff_id=#{staff.id}")
      params[:roles].split(",").each do |r_id|
        StaffRoleRelation.create(:staff_id => staff.id,:role_id => r_id)
      end
      status = 1
    end
    render :json => {:status => status}
  end

  private

  def find_store
    @store = Store.find_by_id(params[:store_id]) || not_found
  end
end
