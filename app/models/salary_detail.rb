#encoding: utf-8
class SalaryDetail < ActiveRecord::Base
  belongs_to :staff
  belongs_to  :violation_reward

  BASE_SCORE = {:SCORE => 90} #90分为标准分，90分以下每低一份按基本工资的百分之一计算

  def self.generate_day_salary #生成每日工资单
    SalaryDetail.destroy_all("current_day = #{(Time.now - 1.days).strftime("%Y%m%d").to_i}") #删除已经生成的日工资，避免出现相同的日工资
    cal_day = (Time.now - 1.days).strftime("%Y-%m-%d")
    start_at_sql = "created_at >= '#{cal_day} 00:00:00'"
    end_at_sql = "date_format(created_at,'%Y-%m-%d') <= '#{cal_day}'"
    order_search_sql = "front_staff_id = ? or cons_staff_id_1 = ? or cons_staff_id_2 = ?"
    complaint_search_sql = "staff_id_1 = ? or staff_id_2 = ?"
    process_at_sql = "process_at >= '#{cal_day}' and date_format(process_at,'%Y-%m-%d') <= '#{cal_day}'"

    violation_rewards = ViolationReward.where(process_at_sql).group_by{|v|v.staff_id}

    violation_rewards.each do |key, vio_rew_array|
      staff = Staff.find_by_id(key)
      violation_amount, reward_amount = 0, 0
      vio_rew_array.each do |vio_rew|
        if vio_rew.types#奖励
          reward_amount += get_reward_amount(staff, vio_rew)
        else #违规
          violation_amount += get_violation_amount(staff, vio_rew)
        end
      end

      satisfied_perc = get_satisfied_perc(start_at_sql, end_at_sql, order_search_sql, complaint_search_sql, key, process_at_sql)
      SalaryDetail.create(:deduct_num => violation_amount, :staff_id => key,
                        :current_day => (Time.now - 1.days).strftime("%Y%m%d").to_i,
                        :satisfied_perc => satisfied_perc, :reward_num => reward_amount)
    end
  end


  def self.get_reward_amount(staff, vio_rew)
    reward_amount = 0
    if staff.is_score_ge_salary && !vio_rew.score_num.nil?
      reward_amount += staff.base_salary * (vio_rew.score_num >= 90 ? (vio_rew.score_num - SalaryDetail::BASE_SCORE[:SCORE]) : 0) * 0.01
    end
    if !vio_rew.salary_num.nil?
      reward_amount += vio_rew.salary_num
    end
    reward_amount
  end

  def self.get_violation_amount(staff, vio_rew)
    violation_amount = 0
    if staff.is_score_ge_salary && !vio_rew.score_num.nil?
      violation_amount += staff.base_salary * (vio_rew.score_num <= 90 ? (SalaryDetail::BASE_SCORE[:SCORE] - vio_rew.score_num) : 0) * 0.01
    end
    if !vio_rew.salary_num.nil?
      violation_amount += vio_rew.salary_num
    end
    violation_amount
  end

  def self.get_satisfied_perc(start_at_sql, end_at_sql, order_search_sql, complaint_search_sql, staff_id, process_at_sql)
    total_order = Order.where(start_at_sql).where(end_at_sql).
                        where(order_search_sql,staff_id, staff_id, staff_id).count

    total_complaint = Complaint.where(process_at_sql).
                                where(complaint_search_sql, staff_id, staff_id).count

    satisfied_perc = total_order == 0 ? 100 : 100 - total_complaint * 100 / total_order
    satisfied_perc
  end

end
