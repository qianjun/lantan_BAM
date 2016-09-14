#encoding: utf-8
class SalariesController < ApplicationController
  before_filter :sign?

  def destroy
    @store = Store.find_by_id(params[:store_id])
    salary = Salary.find_by_id(params[:id])
    salary.update_attribute(:status, true) if salary
    @salaries = salary.staff.salaries.where("status = false").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage)
    respond_to do |format|
      format.js
    end
  end

  def update
    salary = Salary.where(:staff_id=>params[:id],:current_month=>(params[:current_month].delete "-").to_i).first
    staff = salary.staff
    if salary.is_edited
      reward_fee = salary.reward_fee.nil? ? 0 : salary.reward_fee
      pre_total = (salary.reward_num - salary.voilate_fee + salary.work_fee + salary.manage_fee - salary.tax_fee +  reward_fee + salary.deduct_num).round(2)
      total_price = (params[:reward_num].to_f.round(2) - params[:voilate_fee].to_f.round(2) + params[:work_fee].to_f.round(2) +
        params[:manage_fee].to_f.round(2) - params[:tax_fee].to_f.round(2)+ params[:deduct_num].to_f.round(2) + params[:reward_fee].to_f.round(2)).round(2)
      fact_fee = (salary.fact_fee + total_price-pre_total).round(2)
      salary.update_attributes(:reward_num => params[:reward_num].to_f.round(2),:work_fee=>params[:work_fee].to_f.round(2),:manage_fee=>params[:manage_fee].to_f.round(2),
        :tax_fee=>params[:tax_fee].to_f.round(2),:voilate_fee => params[:voilate_fee].to_f.round(2),:fact_fee =>fact_fee,:deduct_num=>params[:deduct_num].to_f.round(2),:reward_fee=>params[:reward_fee].to_f.round(2)) if salary
    end
    render :json =>{:msg=>salary.is_edited,:name=>staff.name,:salary =>salary,:total=>salary.fact_fee}
  end
  
end
