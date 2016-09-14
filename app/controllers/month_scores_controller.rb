#encoding: utf-8
class MonthScoresController < ApplicationController
  before_filter :sign?
  before_filter :get_current_month_score
  def update
    @store = Store.find_by_id(params[:store_id])
    @month_score = MonthScore.find_by_id(params[:id])
    @month_score.update_attributes(params[:month_score]) if @month_score
    @month_scores = @month_score.staff.month_scores.order("current_month desc").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update_sys_score
    month_score = MonthScore.find_by_id(params[:month_score_id])
    if month_score
      month_score.update_attribute(:sys_score, params[:sys_score])
      render :text => "success"
    else
      render :text => "error"
    end
  end

  private
  def get_current_month_score
    staff = Staff.find_by_id(params[:staff_id])
    current_month = Time.now().months_ago(1).strftime("%Y%m")
    @current_month_score = staff.month_scores.where("current_month = #{current_month}").first if !staff.nil?
  end

  
end
