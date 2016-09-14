#encoding: utf-8
class TrainsController < ApplicationController
  before_filter :sign?
  layout "staff"

  def create
    @store = Store.find_by_id(params[:store_id])
    certificate = params[:train][:certificate]
    Train.transaction do
      begin
        params[:staff][:id].each do |staff_id|
          params[:train][:certificate] = certificate.eql?("0") ? 0 : 1
          train = Train.new(params[:train])
          train.train_staff_relations.new({:staff_id => staff_id, :status => 1}) #是否通过考核默认为没有，status=1
          train.save
          work_r = WorkRecord.where(:staff_id=>staff_id,:current_day=>Time.now.strftime("%Y-%m-%d")).first
          work_r.update_attributes(:train_num=>work_r.train_num.nil? ? 1 : work_r.train_num+1)  if work_r
        end
        flash[:notice] = "新建培训成功!"
      rescue
        flash[:notice] = "新建培训失败!"
      end
    end
    redirect_to store_staffs_path(@store)
  end

  def update
    train_staff_relation = TrainStaffRelation.where("staff_id = #{params[:staff_id]} and train_id = #{params[:id]}").first
    train_staff_relation.update_attribute(:status, false) if train_staff_relation
    render :text => "success"
  end
  
end
