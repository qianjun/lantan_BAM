#encoding: utf-8
namespace :salary_list do
  desc "salary of day"
  task(:salary_of_day => :environment) do
    SalaryDetail.generate_day_salary
  end

  desc "salary of month"
  task(:month_salary => :environment) do
    time = Time.now.to_i
    run_time = Salary.generate_month_salary
    p "gerate staff's salary,current time has #{run_time} staffs,run time: #{(Time.now.to_i - time)/3600.0}"
  end

end