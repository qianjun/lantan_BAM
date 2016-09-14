#encoding: utf-8
module StaffsHelper
  
  def current_month_access_result(month_score)
    total = 100- (month_score.nil? ? 0 : month_score.sys_score.to_i)
    if total >= 90
      access_result = "优秀"
    end
    if total >= 80 && total < 90
      access_result = "良好"
    end
    if total >= 70 && total < 80
      access_result = "一般"
    end
    if total >= 60 && total < 70
      access_result = "及格"
    end
    if total < 60
      access_result = "不及格"
    end
    access_result
  end

  def get_month_score_obj(staff)
    staff.month_scores.where("current_month = #{DateTime.now.months_ago(1).strftime("%Y%m")}").first
  end

  def get_train_status(train_id, staff_id)
    train_staff_relation = TrainStaffRelation.where("train_id = #{train_id} and staff_id = #{staff_id}").first
    train_staff_relation.status
  end

end
