#encoding: utf-8
namespace :work_record_list do
  desc "generate work record of day"
  task(:generate_work_record => :environment) do
    WorkRecord.update_record
  end
end