#encoding: utf-8
require "uri"
class StaffsController < ApplicationController
  before_filter :sign?
  layout "staff"
  before_filter :get_store
  before_filter :search_work_record, :only => :show

  def index
    @staffs_names = @store.staffs.not_deleted.where("type_of_w is not null").select("id, name")
    @staffs = @store.staffs.not_deleted.where("type_of_w is not null").paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
    @staff_scores_hash = MonthScore.select("sum(sys_score) sys_score,staff_id").where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")}
   and store_id = ?", @store.id).group("staff_id").inject(Hash.new){|hash,month| hash[month.staff_id] = month;hash}
    @violations = ViolationReward.joins(:staff).where(:status => false).where("staffs.store_id=#{@store.id}").select("violation_rewards.*,staffs.name").group_by{|i| i.types }
    @staff =  Staff.new
    departs = Department.where(:store_id=>@store.id,:status=>Department::STATUS[:NORMAL])
    @departs = departs.inject(Hash.new){|hash,depar| hash[depar.types].nil? ? hash[depar.types]={depar.id=>depar} : hash[depar.types][depar.id]=depar;hash}
    @index_dearts = departs.inject(Hash.new){|hash,depar| hash[depar.id]=depar.name;hash}
    @violation_reward = ViolationReward.new
    @train = Train.new
    @latest_updated_at = Staff.maximum("updated_at").strftime("%Y-%m-%d") unless Staff.maximum("updated_at").blank?
  end

  def search
    name_condi = params[:name].gsub('%', '\%')
    name_sql = params[:name].blank? ? "1=1" : ["name like (?)", "%"+name_condi+"%"]
    #name_sql = params[:name].blank? ? "1=1" : ["name like ?", "%#{params[:name]}%"]
    types_sql = params[:types]=="-1" ? "1=1" : ["type_of_w = ?", "#{params[:types]}"]
    status_sql = params[:status]=="-1" ? "1=1" : ["status = ?", "#{params[:status]}"]
    type_of_w_sql = "type_of_w != #{Staff::S_COMPANY[:BOSS]}"
    @staffs = @store.staffs.not_deleted.where(type_of_w_sql).where(name_sql).where(types_sql).where(status_sql).paginate(:page => params[:page] ||= 1, :per_page => Constant::PER_PAGE)
    departs = Department.where(:store_id=>@store.id,:status=>Department::STATUS[:NORMAL])
    @departs = departs.inject(Hash.new){|hash,depar| hash[depar.types].nil? ? hash[depar.types]={depar.id=>depar} : hash[depar.types][depar.id]=depar;hash}
    @index_dearts = departs.inject(Hash.new){|hash,depar| hash[depar.id]=depar.name;hash}
    @staff_scores_hash = MonthScore.select("sum(sys_score) sys_score,staff_id").where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")}
   and store_id = ?", @store.id).group("staff_id").inject(Hash.new){|hash,month| hash[month.staff_id] = month;hash}
  end

  def create
    params[:staff][:username] = params[:staff][:phone]
    params[:staff][:password] = params[:staff][:phone] if params[:is_access] &&  params[:is_access].to_i ==1
    params[:staff][:status] = Staff::STATUS[:normal]
    @staff = @store.staffs.new(params[:staff])
    @staff.encrypt_password if params[:is_access] &&  params[:is_access].to_i ==1
    photo = params[:staff][:photo]
    encrypt_name = random_file_name(photo.original_filename) if photo
    @staff.photo = "/uploads/#{@store.id}/#{@staff.id}/"+encrypt_name+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
    #@staff.staff_role_relations.new(:role_id => Constant::STAFF)
    if @staff.save   #save staff info and picture
      @staff.operate_picture(photo,encrypt_name +"."+photo.original_filename.split(".").reverse[0], "create") unless photo.nil?
      flash[:notice] = send_message(@staff)
      @flash_notice = "success"
    else
      @flash_notice = "创建员工失败! #{@staff.errors.messages.values.flatten.join("<br/>")}"
    end
    #redirect_to store_staffs_path(@store)
  end

  def show       
    @violations = @staff.violation_rewards.where("types = false").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("violation_tab")
    @rewards = @staff.violation_rewards.where("types = true").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("reward_tab")
    @trains = Train.includes(:train_staff_relations).where("train_staff_relations.staff_id = #{@staff.id}").
      paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("train_tab")
    @month_scores = @staff.month_scores.order("current_month desc").paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("month_score_tab")
    @salaries = @staff.salaries.paginate(:page => params[:page] ||= 1, :per_page => Staff::PerPage) if @tab.nil? || @tab.eql?("salary_tab")
    current_month = Time.now().months_ago(1).strftime("%Y%m")
    @current_month_score = @staff.month_scores.where("current_month = #{current_month}").first
    @departs = Department.where(:store_id=>@store.id,:status=>Department::STATUS[:NORMAL]).inject(Hash.new){|hash,depar| hash[depar.id]=depar.name;hash}
    respond_to do |format|
      format.html
      format.js
    end
  end

  def edit
    @departs = Department.where(:store_id=>@store.id,:status=>Department::STATUS[:NORMAL]).inject(Hash.new){
      |hash,depar| hash[depar.types].nil? ? hash[depar.types]={depar.id=>depar} : hash[depar.types][depar.id]=depar;hash}
    @staff = Staff.find_by_id(params[:staff_id])
    respond_to do |format| 
      format.js
    end
  end

  def update
    @staff = Staff.find_by_id(params[:id])
    photo = params[:staff][:photo]
    encrypt_name = random_file_name(photo.original_filename) if photo
    params[:staff][:photo] = "/uploads/#{@store.id}/#{@staff.id}/"+encrypt_name+"_#{Constant::STAFF_PICSIZE.first}."+photo.original_filename.split(".").reverse[0] unless photo.nil?
    if params[:is_access] &&  params[:is_access].to_i ==1 && @staff.encrypted_password.nil?
      params[:staff][:password] = params[:staff][:phone]
      @staff.encrypt_password
    else
      params[:staff][:encrypted_password] = nil
      params[:staff][:salt] = nil
    end
    @staff.attributes = params[:staff]
    notice = @staff.status_changed? ? "员工在职状态已经改变，请注意检查员工的工作状态" : ""
    if @staff && @staff.save
      #if  @staff && @staff.update_attributes(params[:staff])
      flash[:notice] = "更新员工成功！"+notice
      @flash_notice = "success"
    else
      @flash_notice = "更新员工失败! #{@staff.errors.messages.values.flatten.join("<br/>")}"
    end
    #update picture
    @staff.operate_picture(photo,encrypt_name +"."+photo.original_filename.split(".").reverse[0], "update") if !photo.nil? && @staff
    #redirect_to store_staff_path(@store, @staff)
  end

  def destroy
    Staff.update(params[:id],status: Staff::STATUS[:deleted])
    flash[:notice] = "成功删除员工"
    redirect_to store_staffs_path(@store)
  end

  #  def validate_phone
  #    staff = Staff.find_by_phone(params[:phone])
  #    if staff && staff.status != Staff::STATUS[:deleted]
  #      render :text => "error"
  #    else
  #      render :text => "success"
  #    end
  #  end
  
  #加载职务
  #  def load_work
  #    render :json=>Department.where(:store_id=>@store.id,:status=>Department::STATUS[:NORMAL],:types=>Department::TYPES[:POSITION])
  #  end

  private

  def get_store
    @store = Store.find_by_id(params[:store_id])
  end

  def search_work_record
    @staff = Staff.find_by_id(params[:id])
    @tab = params[:tab]

    if @tab.nil? || @tab.eql?("work_record_tab")
      @work_records = WorkRecord.where(:staff_id=>@staff).where("current_day <=date_add(now(), interval 1 year)").
        select("count(*) num,date_format(current_day,'%Y-%m') time,attend_types").
        group("time,attend_types").order("time desc").inject({}){|h,w|h[w.time].nil? ? h[w.time]={w.attend_types =>w.num} : h[w.time][w.attend_types]=w.num;h }
      #      if @cal_style.eql?("week") || @cal_style.eql?("month")
    end
  end

  def send_message(staff)
    if staff.store
      content = "#{staff.name}, 您已经被添加为(#{staff.store.name})的员工, 您登录门店后台管理系统的的账号为#{staff.username}, 密码为#{staff.username}, 修改密码请登录#{Constant::SERVER_PATH}"
      MessageRecord.transaction do
        begin
          notice = message_data(staff.store_id,content,staff,nil,MessageRecord::M_TYPES[:ADD_STAFF])
        rescue
          notice = "短信通道忙碌，请稍后重试。"
        end
      end
    end
    notice = "短信发送成功，账户信息已经发送到手机中。" if notice.nil?
  end


  
end
