#encoding: utf-8
class WorkRecordsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store
  
  def index
    @staffs = WorkRecord.joins(:staff).select('staffs.name,staffs.type_of_w, staffs.level,work_records.id,attend_types').where("
      staffs.store_id=#{params[:store_id]} and date_format(work_records.created_at,'%Y-%m-%d')='#{Time.now.strftime('%Y-%m-%d')}'
      and staffs.type_of_w != #{Staff::S_COMPANY[:BOSS]}").paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
  end

  def adjust_types
    begin
      WorkRecord.find(params[:id]).update_attributes(:attend_types=>params[:types])
      msg = "状态更新成功"
    rescue => error
#      raise 
      msg = "状态更新失败"
    end
#    p error.message
#    p error.exception
#    p error.backtrace.join("\n")
    render :json=>{:msg=>msg}
  end

  private
  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
end