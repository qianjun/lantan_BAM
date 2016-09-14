#encoding: utf-8
namespace :monthly do
  require 'rubygems'
  require 'google_chart'
  require 'net/https'
  require 'uri'
  require 'open-uri'
  desc "use deiffent data to generate pie chart from google chart  "
  task(:pie_charts => :environment) do
    # Pie Chart
    GoogleChart::PieChart.new('320x200', "Pie Chart",false) do |pc|
      pc.data "Apples", 40
      pc.data "Banana", 20
      pc.data "Peach", 30
      pc.data "Orange", 60
      puts "\nPie Chart"
      puts pc.to_url

      # Pie Chart with no labels
      pc.show_labels = false
      puts "\nPie Chart (with no labels)"
      puts pc.to_url
    end

  end
end



