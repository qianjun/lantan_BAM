#encoding: utf-8
namespace :update_cpcard do
  desc "auto update cpcard status" #用来更新用户套餐卡的状态
  task(:cpc_status => :environment) do
    relations = CPcardRelation.find_all_by_status(CPcardRelation::STATUS[:NORMAL])
    relations.each do |r|
      if r.ended_at and r.ended_at <= Time.now
        r.update_attribute(:status, CPcardRelation::STATUS[:INVALID])
      else
        prod_infos = r.content.split(",") if r.content
        zero_length = 0
        prod_infos.each do |p|
          p_i = p.split("-")
          num = p_i[2] if p_i
          zero_length += 1 if num.to_i == 0
        end unless prod_infos.blank?
        r.update_attribute(:status, CPcardRelation::STATUS[:INVALID]) if zero_length == prod_infos.length
      end
    end unless relations.blank?
  end

end