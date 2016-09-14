module StaffManagesHelper
  def get_last_ten_years
    years = []
    10.times do |i|
      years << DateTime.now.years_ago(i).strftime("%Y")
    end
    years
  end
end
