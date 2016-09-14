#encoding: utf-8
desc "filter the right staff for stations"
task :today do
  Rake::Task["daily:control_status"].invoke
end

namespace :daily do
  task(:set_stations => :environment) do
    Store.all.each {|store| Station.set_stations(store.id)}
  end

  task(:set_station => :environment) do
    Store.all.each {|store|
      StationStaffRelation.delete_all(:store_id => store.id)
      Staff.where("store_id=#{store.id} and type_of_w=#{Staff::S_COMPANY[:TECHNICIAN]} and status=#{Staff::STATUS[:normal]}").each {|staff|
        Station.set_station(store.id,staff.id,staff.level) }
    }
  end

  task(:revist_message => :environment) do
    #客户在不同门店的消费回访会作为多次发送，同一个门店的则只做单次发送
    Product.revist #根据回访要求发送客户短信，会查询所有的门店信息发送,设置的时间为每天的11:30和晚8点半左右，每天两次执行
  end
  #同步本店的数据
  task(:sync_local_data => :environment) do
    Store.all.each {|store| Sync.out_data(store.id)}
  end
  #同步总部的数据
  task(:request_zip_again => :environment) do
    #syncs = Sync.where("types=#{Sync::SYNC_TYPE[:SETIN]} and (sync_status == null or sync_status = #{Sync::SYNC_STAT[:ERROR]})")
    #syncs.each do |sync|
    #  day = (Time.now - sync.created_at).strftime("%d")
    #  Sync.request_is_generate_zip(day)
    #end
    Sync.request_is_generate_zip(Time.now)
  end



  #后台检测程序 将十天之内未使用的门店关闭
  task(:control_status => :environment) do
    time = Time.now.to_i
    closed_store = []
    Staff.joins(:store).where(:stores=>{:status=>Store::STATUS[:OPENED]},:staffs=>{:status=>Staff::STATUS[:normal]}).
      select("store_id,date_format(ifnull(max(last_login),now()),'%Y-%m-%d') login_time").group("store_id").each {|store|
      closed_store << store.store_id if store.login_time.to_datetime.advance(:days => 10) < Time.now; }
    Store.where(:id=>closed_store).update_all(:status=>Store::STATUS[:CLOSED],:close_reason=>"门店已关闭，请联系技术人员！") unless closed_store.blank?
    p "#{Time.now.strftime('%Y-%m-%d')} closed store's number is #{closed_store.length},and ids' #{closed_store}"

    time = Time.now.to_i
    Station.turn_old_to_new  #生成员工的工作记录
    p "work records gernaerate #{(Time.now.to_i - time)/3600.0}"
  end

end