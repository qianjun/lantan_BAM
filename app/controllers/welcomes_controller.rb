#encoding: utf-8
class WelcomesController < ApplicationController
  before_filter :sign?
  before_filter :customer_tips,:material_order_tips,:get_voilate_reward, :except => [:edit_store_name, :update_staff_password]

  def index

    store = Store.find_by_id(params[:store_id].to_i)
    @staff = Staff.find_by_id(cookies[:user_id])
    cookies[:store_name] = {:value => store.name, :path => "/", :secure => false} if store
    #cookies[:store_id] = {:value => store.id, :path => "/", :secure => false} if store
    @warns = warn_account(0.8,5,0)
    @show_index = Log.where(:show_index=>Log::SHOW_INDEX[:YES],:status=>Log::STATUS[:NOMARL]).first
    @roll_news = Log.where(:roll=>Log::ROLL[:YES],:status=>Log::STATUS[:NOMARL],:store_types=>[0,store.id]).order("store_types desc")
    render :index, :layout => false
  end

  def edit_store_name
    if Store.where(["id != ? and name = ?", params[:store_id].to_i,params[:name].strip]).blank?
      store = Store.find_by_id(params[:store_id].to_i)
      if store.nil?
        render :json => {:status => 0}
      else
        if store.update_attribute("name", params[:name].strip)
          cookies.delete(:store_name)
          cookies[:store_name] = {:value => store.name, :path => "/", :secure => false}
          render :json => {:status => 1, :new_name => store.name}
        else
          render :json => {:status => 0}
        end
      end
    else
      render :json => {:status => 2}
    end
  end

  def update_staff_password
    @flag = false
    if params[:new_password] != params[:confirm_password]
      @notice = "新密码和确认密码不一致！"
      return
    end
    staff = Staff.find_by_id(cookies[:user_id])
    if staff.has_password?(params[:old_password])
      staff.password = params[:new_password]
      staff.encrypt_password
      if staff.save
        @notice = "密码修改成功！"
        @flag = true
      else
        @notice = "密码修改失败! #{staff.errors.messages.values.flatten.join("<br/>")}"
      end
    else
      @notice = "请输入正确的旧密码！"
    end
  end

  def info_detail
    @log = Log.find(params[:log_id])
  end

end
