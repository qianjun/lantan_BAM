#encoding: utf-8
class ViolationRewardsController < ApplicationController
  before_filter :sign?
  layout "staff"

  before_filter :get_store

  def create
    ViolationReward.transaction do
      begin
        params[:violation_reward][:status] = ViolationReward::STATUS[:NOMAL]
        params[:staff][:id].each do |staff_id|
          violation_reward = ViolationReward.new(params[:violation_reward])
          violation_reward.staff_id = staff_id
          violation_reward.save
        end
        flash[:notice] = params[:violation_reward][:types] == "1" ? "新建奖励成功!" : "新建违规成功!"
      rescue
        flash[:notice] = params[:violation_reward][:types] == "1" ? "新建奖励失败!" : "新建违规失败!"
      end
    end
    redirect_to store_staffs_path(@store)
  end

  def edit
    @violation_reward = ViolationReward.find_by_id(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def update
    @violation_reward = ViolationReward.find_by_id(params[:id])
    params[:violation_reward][:process_at] = Time.now
    @violation_reward.update_attributes(params[:violation_reward]) if @violation_reward
    @simple = params[:simple]
    if @simple   #快捷处理通道
      @violations = ViolationReward.joins(:staff).where(:status =>false,:types=>@violation_reward.types).where("staffs.store_id=#{@store.id}").select("violation_rewards.*,staffs.name")
    else #常规处理
      if @violation_reward.types
        @rewards = @violation_reward.staff.violation_rewards.where("types = true").
          paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
      else
        @violations = @violation_reward.staff.violation_rewards.where("types = false").
          paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
      end
    end
    #更新员工考核记录的奖惩部分
    salary_num = params[:violation_reward][:salary_num]
    work_r = WorkRecord.where(:staff_id=>@violation_reward.staff_id,:current_day=>Time.now.strftime("%Y-%m-%d")).first
    if work_r && salary_num && salary_num.to_i != 0
      if @violation_reward.types
        work_r.update_attributes(:reward_num=>work_r.reward_num.nil? ? salary_num.to_f : work_r.reward_num + salary_num.to_f)
      else
        work_r.update_attributes(:violation_num=>work_r.violation_num.nil? ? salary_num.to_f : work_r.violation_num + salary_num.to_f)
      end
    end
    respond_to do |format|
      format.js
    end
  end

  def operate_voilate
    begin
      @voi = ViolationReward.find(params[:id])
      @voi.update_attributes(:status=>true,:process_at=>Time.now.strftime("%Y-%m-%d"),
        :mark=>"使用快捷处理方式,无效",:score_num=>0,:salary_num=>0)
      @msg = "处理成功"
    rescue => error
      @msg = "处理失败"
    end
    @violations = ViolationReward.joins(:staff).where(:status =>false,:types=>@voi.types).where("staffs.store_id=#{@store.id}").select("violation_rewards.*,staffs.name")
  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end
  
end
