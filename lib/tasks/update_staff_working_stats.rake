#encoding: utf-8
namespace :staff_working_stats do
  desc "update staff working stats"
  task(:update_staff_working_stats => :environment) do
    Staff.update_staff_working_stats
  end

end