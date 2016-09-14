#encoding: utf-8
class Salary < ActiveRecord::Base
  belongs_to :staff

  def self.generate_month_salary
    #说明:员工的工资 =  基本工资 + 提成金额 + 奖励金额 - 违规金额 + 补贴金额 - 社保金额
    start_time = Time.now.months_ago(1).at_beginning_of_month
    Salary.destroy_all("current_month = #{start_time.strftime("%Y%m")}") #删除已经生成的月工资，避免重复生成
    end_time = Time.now.months_ago(1).at_end_of_month
    #统计奖励和违规的金额
    salary_infos = ViolationReward.select("staff_id,sum(salary_num) num,types").where(:status=>ViolationReward::STATUS[:PROCESSED]).
      where("created_at >= '#{start_time}' and created_at <= '#{end_time}'").group("staff_id,types").inject(Hash.new){
      |hash,s|hash[s.staff_id].nil? ? hash[s.staff_id]={s.types=>s.num}:hash[s.staff_id][s.types]=s.num;hash }
    #前台提成金额
    front_amount = get_front_deduct_amount(start_time, end_time)
    #技师提成金额
    technician_amount = get_technician_deduct_amount(start_time, end_time)
    gr_records = StaffGrRecord.where("created_at >= '#{start_time}' and created_at <= '#{end_time}'").order('created_at asc').inject(Hash.new){
      |hash,r|hash[r.staff_id]=r;hash}
    staffs = Staff.not_deleted
    staffs.each do |staff|
      voilate_amount = salary_infos[staff.id].nil? ? 0 : salary_infos[staff.id][false].nil? ? 0 : salary_infos[staff.id][false]
      reward_amount = salary_infos[staff.id].nil? ? 0 : salary_infos[staff.id][true].nil? ? 0 : salary_infos[staff.id][true]
      if staff.working_stats == 1
        staff_gr_record = gr_records[staff.id]
        base_salary = (!staff_gr_record.nil? && !staff_gr_record.working_stats) ? staff.probation_salary : staff.base_salary
      else
        base_salary = staff.probation_salary
      end
      base_salary = base_salary.nil? ? 0 : base_salary
      reward = staff.reward_fee.nil? ? 0 : staff.reward_fee
      secure = staff.secure_fee.nil? ? 0 : staff.secure_fee
      parms = {:reward_num => reward_amount,:voilate_fee=>voilate_amount,:current_month => start_time.strftime("%Y%m"),
        :staff_id => staff.id, :satisfied_perc => 100,:reward_fee=>staff.reward_fee,:secure_fee=>staff.secure_fee}
      if staff.is_deduct
        total_deduct =  front_amount[staff.id].nil? ? 0 :  front_amount[staff.id]
        total_deduct +=  technician_amount[staff.id].nil? ? 0 :  technician_amount[staff.id]
        total = base_salary + reward_amount - voilate_amount + total_deduct + reward - secure
      else
        total_deduct = 0
        total = base_salary + reward_amount - voilate_amount + reward - secure
      end
      Salary.create(parms.merge({:total => total,:deduct_num => total_deduct,:fact_fee=>total,:base_salary=>base_salary,:is_edited=>1}))
    end
    return staffs.length
  end

  def self.get_violation_reward_amount(salary_infos)
    staff_deduct_reward_hash = {} #奖励违规的金额
    salary_infos.each do |staff_id, salary_details|
      staff_deduct_reward_hash[staff_id] = {:deduct_num => salary_details.sum(&:deduct_num),
        :reward_num => salary_details.sum(&:reward_num)}
    end
    staff_deduct_reward_hash
  end

  def self.get_front_deduct_amount(start_time, end_time)
    return Order.select("sum(front_deduct) sum,front_staff_id").where("created_at >= '#{start_time}' and created_at <='#{end_time}'").
      where("status = #{Order::STATUS[:BEEN_PAYMENT]} || status = #{Order::STATUS[:FINISHED]}").group("front_staff_id").inject(Hash.new){
      |hash,order| hash[order.front_staff_id] = order.sum;hash}
  end

  def self.get_technician_deduct_amount(start_time, end_time)
    technician_deduct_amount = Order.joins(:tech_orders).select("sum(tech_orders.own_deduct) deduct_price,tech_orders.staff_id").
      where("orders.created_at >=  '#{start_time}' and orders.created_at <='#{end_time}'").
      where(:"orders.status"=>Order::PRINT_CASH).group("tech_orders.staff_id").inject({}){|h,s|h[s.staff_id]=s.deduct_price;h}
    technician_deduct_amount
  end

  def self.get_avg_percent(start_time, end_time)
    orders = Order.find_by_sql("select o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2, count(*) total_count from orders o left join staffs s on o.cons_staff_id_1 =  s.id
       left join staffs s2 on o.cons_staff_id_2 = s2.id left join staffs s3 on o.front_staff_id = s3.id where o.created_at >= '#{start_time}' and o.created_at <='#{end_time}'
       and (o.status = #{Order::STATUS[:BEEN_PAYMENT]} or o.status = #{Order::STATUS[:FINISHED]})
       group by o.front_staff_id, o.cons_staff_id_1, o.cons_staff_id_2")

    orders_info = {}
    orders.each do |order|
      if orders_info.keys.include?(order.front_staff_id)
        orders_info[order.front_staff_id] += order.total_count
      else
        orders_info[order.front_staff_id] = order.total_count
      end
      if orders_info.keys.include?(order.cons_staff_id_1)
        orders_info[order.cons_staff_id_1] += order.total_count if order.cons_staff_id_1 != order.front_staff_id
      else
        orders_info[order.cons_staff_id_1] = order.total_count
      end

      if orders_info.keys.include?(order.cons_staff_id_2)
        orders_info[order.cons_staff_id_2] += order.total_count if order.cons_staff_id_2 != order.front_staff_id && order.cons_staff_id_2 != order.cons_staff_id_1
      else
        orders_info[order.cons_staff_id_2] = order.total_count
      end
    end

    complaints = Complaint.find_by_sql("select c.staff_id_1, c.staff_id_2, count(*) total_count from complaints c left join staffs s on c.staff_id_1 = s.id
       left join staffs s2 on c.staff_id_2 = s2.id where c.process_at >= '#{start_time}' and c.process_at <='#{end_time}'
       group by c.staff_id_1, c.staff_id_2")

    complaints_info = {}
    complaints.each do |complaint|
      if complaints_info.keys.include?(complaint.staff_id_1)
        complaints_info[complaint.staff_id_1] += complaint.total_count
      else
        complaints_info[complaint.staff_id_1] = complaint.total_count
      end
      if complaints_info.keys.include?(complaint.staff_id_2)
        complaints_info[complaint.staff_id_2] += complaint.total_count if complaint.staff_id_1 != complaint.staff_id_2
      else
        complaints_info[complaint.staff_id_2] = complaint.total_count
      end
    end
    result = {}
    orders_info.each do |staff_id, order_count|
      if complaints_info[staff_id.to_i].nil?
        result[staff_id] = 100
      else
        result[staff_id] = (order_count == 0 ? 100 :complaints_info[staff_id.to_i]*100/order_count)
      end
    end
    result
  end
  
end
