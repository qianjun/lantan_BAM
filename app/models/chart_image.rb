#encoding: utf-8
require 'google_chart'
require 'net/https'
require 'uri'
require 'open-uri'
class ChartImage < ActiveRecord::Base
  TYPES = {:SATIFY =>0,:COMPLAINT =>1,:MECHINE_LEVEL =>2,:FRONT_LEVEL =>3,:STAFF_LEVEL =>4}
  # 0 满意度 1 投诉统计 2 技师平均水平 3 前台平均水平 4 员工绩效

  #定时生成技师，接待平均水平统计表
  def self.generate_avg_chart_image
    year = Time.now.months_ago(1).strftime("%Y")
    month = Time.now.months_ago(1).strftime("%m")
    stores = Store.all
    avg_month_scores = {}
    stores.each do |store|
      avg_month_scores[store.id] = get_month_score_data(store, year, month)
    end
    generate_chart_images(avg_month_scores)
  end

  def self.get_month_score_data(store, year, month)
    month_scores = MonthScore.includes(:staff => :store).where("stores.id = #{store.id}").
      where("month_scores.current_month >= #{year}01 and month_scores.current_month <= #{year}#{month}").
      where("staffs.type_of_w = #{Staff::S_COMPANY[:FRONT]} or staffs.type_of_w = #{Staff::S_COMPANY[:TECHNICIAN]}").
      group_by{|s|s.staff.type_of_w}
    if month_scores.blank?
      zero_data = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
      return {Staff::S_COMPANY[:TECHNICIAN] => zero_data,
        Staff::S_COMPANY[:FRONT] => zero_data}
    end
    average_score_hart = {}
    month_scores.each do |key, value|
      scores = value.group_by{|m|m.current_month}
      data_array = []
      (1..12).collect{|i|
        key_value = (i>=10 ? year+i.to_s : year+"0#{i.to_s}").to_i
        if scores[key_value].nil?
          data_array << 0
        else
          #total_amount = (scores[key_value].sum(&:manage_score) + scores[key_value].sum(&:sys_score))/scores[key_value].size
          total_amount = (scores[key_value].sum{ |p| p.manage_score ||= 0 } + scores[key_value].sum(&:sys_score))/scores[key_value].size
          data_array << (total_amount > 100 ? 100 : total_amount)
        end
      }
      average_score_hart[key] = data_array
    end
    average_score_hart
  end

  def self.generate_chart_images(avg_month_scores)
    avg_month_scores.each do |store_id, avg_data|
      avg_data.each do |key, value|
        chart_name = key == Staff::S_COMPANY[:TECHNICIAN] ? "技师平均水平统计" : "接待平均水平统计"
        types = key == Staff::S_COMPANY[:TECHNICIAN] ? ChartImage::TYPES[:MECHINE_LEVEL] : ChartImage::TYPES[:FRONT_LEVEL]
        lc = shared_chart_img_options('1000x300', chart_name, value, 100)
        img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),store_id,types,store_id)
        ChartImage.create(:store_id => store_id, :types => types,
          :created_at => Time.now, :image_url => img_url, :current_day => Time.now.months_ago(1))
      end
    end

  end

  def self.shared_chart_img_options(chart_size, chart_name, value, max_value)
    lc = GoogleChart::LineChart.new(chart_size, chart_name, false)
    lc.data chart_name, value , 'ff0000'
    lc.show_legend = true
    lc.max_value max_value
    lc.axis :x, :labels =>['日期(月)1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'], :range => [0,11], :alignment => :center
    lc.axis :y, :labels => [0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100], :range => [0,10], :alignment => :center
    lc.grid :x_step => 100.0/11, :y_step => 100.0/10, :length_segment => 1, :length_blank => 3
    lc
  end

  def self.write_img(url,store_id,types,object_id)  #上传图片
    file_name ="#{Time.now.to_i}_#{object_id}.jpg"
    dir = "#{File.expand_path(Rails.root)}/public/chart_images"
    Dir.mkdir(dir) unless File.directory?(dir)
    total_dir ="#{dir}/#{store_id}/"
    Dir.mkdir(total_dir) unless File.directory?(total_dir)
    all_dir ="#{total_dir}/#{types}/"
    Dir.mkdir(all_dir) unless File.directory?(all_dir)
    file_url ="#{all_dir}#{file_name}"
    open(url) do |fin|
      File.open(file_url, "wb+") do |fout|
        while buf = fin.read(1024) do
          fout.write buf
        end
      end
    end
    return "/chart_images/#{store_id}/#{types}/#{file_name}"
    puts "Chart #{object_id} success generated"
  end

  #每月定时生成员工绩效图表
  def self.generate_staff_score_chart
    year = Time.now.months_ago(1).strftime("%Y")
    month = Time.now.months_ago(1).strftime("%m")
    stores = Store.all
    stores.each do |store|
      store.staffs.each do |staff|
        according_staff_generate_score_chart(staff, year, month)
      end
    end
  end

  def self.according_staff_generate_score_chart(staff, year, month)
    month_scores = staff.month_scores.
      where("current_month >= #{year}01 and current_month <= #{year}#{month}").
      group_by{|s|s.current_month}
    data_array = []
    (1..12).collect{|i|
      key = (i>=10 ? year+i.to_s : year+"0#{i.to_s}").to_i
      if month_scores[key].nil?
        data_array << 0
      else
        total_amount = month_scores[key].sum(&:manage_score) + month_scores[key].sum(&:sys_score)
        data_array << (total_amount > 100 ? 100 : total_amount)
      end
    }
    lc = shared_chart_img_options('600x267', "员工绩效统计表", data_array, 100)
    store_id = staff.store.id
    types = ChartImage::TYPES[:STAFF_LEVEL]
    img_url=write_img(URI.escape(URI.unescape(lc.to_url({:chm => "o,0066FF,0,-1,6"}))),store_id,types,staff.id)
    ChartImage.create(:store_id => store_id, :types => types,
      :created_at => Time.now, :image_url => img_url, 
      :current_day => Time.now.months_ago(1), :staff_id => staff.id)
  end

end
