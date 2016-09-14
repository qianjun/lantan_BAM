#encoding: utf-8
namespace :daily do
  require 'net/https'
  require 'uri'
  require 'mechanize'
  require 'hpricot'
  require 'open-uri'
  require 'rubygems'
  require 'fileutils'
  require 'rexml/document'
  include REXML
  require 'spreadsheet'
  require 'iconv'
  
  desc "Set a time to update car brand every day"
  task(:update_car_brand => :environment) do
    url = "http://car.autohome.com.cn/zhaoche/pinpai/"
    agent = Mechanize.new
    page = agent.get(url)
    p source = Hpricot(Iconv.conv("UTF-8//IGNORE", "GB2312",page.body ))
    p source.search('div[@class=listtitle]').inner_text
    if source.search('div[@class=listtitle]').length != 0
      file = File.open("#{Rails.root}/public/current_cars.txt",'a+')
      time_file = File.open("#{Rails.root}/public/run_times.txt",'a+')
      lastest_file = File.open("#{Rails.root}/public/lastest_cars.txt",'a+')
      capital,n,time = "",0,Time.now
      p total_time = []
      source.search('div[@id=main]').search('div').each do |ppai|
        p each_time = Time.now
        n += 1
        #        break  if n == 100
        if ppai.attributes['class'] == "listtitle"
          capital = ppai.search('a').inner_text
        end
        if ppai.attributes['class'] == "grade_js_top30"
          n_capital = Capital.find_by_name(capital)
          n_capital = Capital.create(:name=>capital) if n_capital
          brands = n_capital.car_brands
          brand = ppai.search("div[@class=grade_js_top31]").search("a").inner_text
          if brands.include? brand
            models = CarBrand.find_by_name(brand).car_models
            ppai.search("div[@class=grade_js_top9]").each do |model|
              first_11 = model.search("div[@class=grade_js_top11]").first.search("a")
              if first_11.first.attributes["title"] == ""
                mmodel = model.search("div[@class=grade_js_top10]").first.search("a")
                p_car = agent.get(mmodel.first.attributes["href"])
                s_car = Hpricot(Iconv.conv("UTF-8//IGNORE", "GB2312",p_car.body )).search("div[@class=tab tab02 tab-ys]")
                current_cars = s_car.search("div[@class=tab-content-item current]").search("li[@class=grey-bg]")
                #                file.write("#{capital}--#{brand}--#{mmodel.inner_text}\r\n") unless models.include? mmodel
                car_texts = []
                current_cars.each do |car|
                  cat_text = car.search("div[@class=interval01-list-cars]").search("p").first.inner_text.split(" ")
                  car_texts << cat_text[1..cat_text.length].join(" ").gsub(/^[\u4E00-\u9FFF]+$/,"").strip
                end
                m_model = mmodel.inner_text
                car_texts.compact.uniq.each  {|car|
                  n_brand,n_model = "",""
                  if m_model.include? brand
                    n_brand = m_model
                    n_model = car
                  elsif car.include?(m_model)
                    n_brand = brand
                    n_model = car
                  else
                    n_model = [m_model,car].join("")
                  end
                  CarModel.create(:name=>n_model,:car_brand_id=>brand.id)
                  file.write("#{n_capital.id}--#{n_brand}--#{n_model}\r\n")
                  lastest_file.write("#{capital}--#{n_brand}--#{n_model}\r\n")}
              else
                mmodel =  first_11
                file.write("#{capital}--#{brand}--#{m_model}\r\n")
              end
            end
          else
            ppai.search("div[@class=grade_js_top9]").each do |model|
              first_11 = model.search("div[@class=grade_js_top11]").first.search("a")
              if first_11.first.attributes["title"] == ""
                mmodel = model.search("div[@class=grade_js_top10]").first.search("a")
                p_car = agent.get(mmodel.first.attributes["href"])
                s_car = Hpricot(Iconv.conv("UTF-8//IGNORE", "GB2312",p_car.body )).search("div[@class=tab tab02 tab-ys]")
                current_cars = s_car.search("div[@class=tab-content-item current]").search("li[@class=grey-bg]")
                #                file.write("#{capital}--#{brand}--#{mmodel.inner_text}\r\n") unless models.include? mmodel
                car_texts = []
                current_cars.each do |car|
                  cat_text = car.search("div[@class=interval01-list-cars]").search("p").first.inner_text.split(" ")
                  car_texts << cat_text[1..cat_text.length].join(" ").gsub(/[\u4e00-\u9fa5]/i,"").strip
                end
                m_model = mmodel.inner_text
                car_brand = CarBrand.create(:capital_id=>n_capital.id,:name=>m_model)
                car_texts.compact.uniq.each  {|car|
                  n_brand,n_model = "",""
                  if m_model.include? brand
                    n_brand = m_model
                    n_model = car
                  elsif car.include?(m_model)
                    n_brand = brand
                    n_model = car
                  else
                    n_brand = brand
                    n_model = [m_model,car].join("")
                  end
                  CarModel.create(:name=>n_model,:car_brand_id=>car_brand.id)
                  file.write("#{capital}--#{n_brand}--#{n_model}\r\n")
                  lastest_file.write("#{capital}--#{n_brand}--#{n_model}\r\n")}
              else
                file.write("#{capital}--#{brand}--#{first_11.inner_text}\r\n")
                lastest_file.write("#{capital}--#{brand}--#{first_11.inner_text}\r\n")
              end
            end
          end
        end
        total_time << Time.now - each_time
      end
      time_file.write("min time：#{total_time.min} max time: #{total_time.max} total time: #{Time.now - time} run times : #{n}\r\n")
      file.close
      lastest_file.close
      time_file.close
    end
   
  end


  desc "Set a time to update car brand every day"
  task(:get_car_brand => :environment) do
    url = "http://price.pcauto.com.cn/cars/"
    agent = Mechanize.new
    page = agent.get(url)
    source = Hpricot(Iconv.conv("UTF-8//IGNORE", "GB2312",page.body ))
    contents = source.search('div[@class=wrap iContent]')
    if contents.search('div[@class=main clearfix]').length != 0
      capitals,ptitles = {},{}
      contents.search('div[@class=main clearfix]').each_with_index do |clearfix,index|
        capital = clearfix.search("div[@class=layA w88]").search("div[@class=dFix]").search("a").search("i").inner_html
        brand_name = clearfix.search("div[@class=layA w88]").search("div[@class=dFix]").search("p").inner_html
        if capitals[capital].nil?
          c = Capital.create(:name=>capital)
          capitals[capital] = c.id
        end
        car_brand = CarBrand.create(:name=>brand_name,:capital_id=>capitals[capital])
        ptitles[car_brand.id] = clearfix.search("div[@class=layB w899 listC]").search("p[@class=pTitle]").inject([]){|arr,p_title|arr << p_title.inner_text.strip.split("(")[0].gsub("(","").gsub("\n","")}
      end
      car_models = []
      ptitles.each {|k,v| v.each{|name|car_models << CarModel.new(:name=>name,:car_brand_id=>k)}}
      CarModel.import car_models
    end
  end


end