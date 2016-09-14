#encoding: utf-8
class WorkRecord < ActiveRecord::Base
  belongs_to :staff
  ATTEND_TYPES = {:ATTEND =>0,:LATE =>1,:EARLY =>2,:LEAVE =>3,:ABSENT =>4}
  ATTEND_NAME = {0=>"出勤",1=>"迟到",2=>"早退",3=>"请假",4=>"旷工"}
  ATTEND_YES =[ATTEND_TYPES[:ATTEND],ATTEND_TYPES[:LATE],ATTEND_TYPES[:EARLY]]

  def self.update_record
    time = Time.now.strftime("%Y-%m-%d")
    work_records = WorkRecord.where("current_day >= '#{time}' and date_format(current_day,'%Y-%m-%d') <= '#{time}'")
    work_records.each do |work_record|
      staff = Staff.find_by_id(work_record.staff_id)
      if staff
        complaint_num = Complaint.where("process_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
          where("date_format(process_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
          where("staff_id_1 = #{work_record.staff_id} or staff_id_2 = #{work_record.staff_id}").
          where("status = #{Complaint::STATUS[:PROCESSED]}").count

        train_num = Train.includes(:train_staff_relations).
          where("train_staff_relations.staff_id = #{work_record.staff_id}").
          where("trains.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
          where("date_format(trains.updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").count

        violation_rewards = ViolationReward.where("staff_id = #{staff.id}").
          where("process_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
          where("date_format(process_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").group_by{|v|v.staff_id}
        violation_num, reward_num = 0, 0

        violation_rewards.each do |key, vio_rew_array|
          vio_rew_array.each do |vio_rew|
            if vio_rew.types#奖励
              reward_num += SalaryDetail.get_reward_amount(staff, vio_rew)
            else #违规
              violation_num += SalaryDetail.get_violation_amount(staff, vio_rew)
            end
          end
        end

        if staff.type_of_w == Staff::S_COMPANY[:TECHNICIAN]  #技师
          construct_num = Order.where("cons_staff_id_1 = #{work_record.staff_id} or cons_staff_id_2 = #{work_record.staff_id}").
            where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}").
            where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
            where("date_format(updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").count

          materials_used_num = MatOutOrder.where("staff_id = #{work_record.staff_id}").
            where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
            where("date_format(updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").sum(:material_num)

          materials_consume_num = materials_used_num
          work_orders = WorkOrder.find_by_sql("select wo.id id, wo.water_num water_num, wo.gas_num gas_num from work_orders wo
                                             left join station_staff_relations ssr on ssr.station_id = wo.station_id
                                             where ssr.staff_id = #{work_record.staff_id} and 
                                             wo.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}' and
                                             date_format(wo.updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}' and
                                             wo.status = #{WorkOrder::STAT[:COMPLETE]} and ssr.updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}' and
                                             date_format(ssr.updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'")
          
          water_num = work_orders.uniq{|x| x.id}.inject(0) {|sum, wo| sum + wo.water_num.to_f }

          gas_num = work_orders.uniq{|x| x.id}.inject(0) {|sum, wo| sum + wo.gas_num.to_f }

          water_num = water_num*10/2*0.1
          gas_num = gas_num*10/2*0.1

          work_record.update_attributes(:construct_num => construct_num, :materials_used_num => materials_used_num,
            :materials_consume_num => materials_consume_num, :water_num => water_num,
            :gas_num => gas_num, :complaint_num => complaint_num, :train_num => train_num,
            :violation_num => violation_num, :reward_num => reward_num)
        else
          if staff.type_of_w == Staff::S_COMPANY[:FRONT]  #前台
            construct_num = Order.where("front_staff_id = #{work_record.staff_id}").
              where("status = #{Order::STATUS[:BEEN_PAYMENT]} or status = #{Order::STATUS[:FINISHED]}").
              where("updated_at >= '#{work_record.current_day.strftime("%Y-%m-%d")}'").
              where("date_format(updated_at,'%Y-%m-%d') <= '#{work_record.current_day.strftime("%Y-%m-%d")}'").count
            work_record.update_attributes(:construct_num => construct_num, :complaint_num => complaint_num,
              :train_num => train_num, :violation_num => violation_num, :reward_num => reward_num)
          else #店长
            work_record.update_attributes(:complaint_num => complaint_num, :train_num => train_num,
              :violation_num => violation_num, :reward_num => reward_num)
          end
        end
      end
    end
  end
end
