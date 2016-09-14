#encoding: utf-8
module SpiderHelper
  require 'net/https'
  require 'uri'
#  require 'mechanize'
#  require 'hpricot'
  require 'open-uri'
  require 'rubygems'
  require 'fileutils'
  require 'rexml/document'
  include REXML
  require 'spreadsheet'
  require 'iconv'

  def get_car_infos
    url = "http://car.autohome.com.cn/zhaoche/pinpai/"
    agent = Mechanize.new
    page = agent.get(url)
    source = Hpricot(Iconv.conv("UTF-8//IGNORE", "GB2312",page.body ))
    if source.search('div[@class=uibox]').length != 0
      file = File.open("#{Rails.root}/public/current_cars.txt",'a+')
      capital,n,time = "",0,Time.now
      p titles = source.search('div[@class=uibox]').search("div[@class=uibox-title]").inject([]){|arr,title|
        arr << title.inner_text
      }
      p cons = source.search('div[@class=uibox]').search("div[@class=uibox-con]").inject([]){|arr,con|
        con.search("dl").each do |c|
          p car_brand = c.search("dt").search("p").second.inner_text
          p car_models = c.search("dd").search("li").inject([]){|li_arr,li|li_arr << li.search("h4").search("a").inner_text}
          arr << {car_brand=>car_models}
        end
        arr
      }
    end
  end

end
