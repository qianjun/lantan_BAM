#encoding: utf-8
class Sync < ActiveRecord::Base
  require 'rubygems'
  require 'net/http'
  require "uri"
  require 'openssl'
  require 'net/http/post/multipart'
  require 'zip/zip'
  require 'zip/zipfilesystem'
  require 'open-uri'
  require 'json'

  SYNC_STAT = {:COMPLETE =>1,:ERROR =>0}  #生成/压缩/上传更新文件 完成1 报错0
  SYNC_TYPE = {:BUILD =>0 , :SETIN => 1}  #生成数据  0  本地数据导入 1
  HAS_DATA = {:YES =>1,:NO =>0}  #1 有更新数据 0  没有更新数据

  #发送上传请求
  def self.send_file(store_id,file_url,filename,sync_time)
    flog = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+".log","a+")
    begin
      query ={:store_id=>store_id,:sync_time =>sync_time}
      url = URI.parse Constant::HEAD_OFFICE
      File.open(file_url) do |file|
        req = Net::HTTP::Post::Multipart.new url.path,query.merge!("upload" => UploadIO.new(file, "application/zip", "#{filename}"))
        http = Net::HTTP.new(url.host, url.port)
        if  http.request(req).body == "success"
          Sync.create(:store_id=>store_id,:sync_at=>Time.zone.parse(sync_time.strftime("%Y-%m-%d %H")),:types=>Sync::SYNC_TYPE[:BUILD])
          flog.write("数据上传成功---#{sync_time.strftime("%Y-%m-%d %H")}\r\n")
        end
      end
    rescue
      flog.write("数据上传失败---#{sync_time.strftime("%Y-%m-%d %H")}\r\n")
      p "#{filename}  file send failed"
    end
    flog.close
  end


  #将文件压缩进zip
  def self.input_zip(file_path,store_id,sync_time)
    get_dir_list(file_path).each {|path|  File.delete(file_path+path) if path =~ /.zip/ }
    filename ="#{sync_time.strftime("%Y%m%d%H") }_#{store_id}.zip"
    Zip::ZipFile.open(file_path+filename, Zip::ZipFile::CREATE) { |zf|
      get_dir_list(file_path).each {|path| zf.file.open(path, "w") { |os| os.write "#{File.open(file_path+path).read}" } }
    }
    return filename
  end


  def self.out_data(store_id)
    path = Constant::LOCAL_DIR
    Dir.mkdir Constant::LOG_DIR  unless File.directory?  Constant::LOG_DIR
    flog = File.open(Constant::LOG_DIR+Time.now.strftime("%Y-%m").to_s+".log","a+")
    sync_time = Time.now
    sync =Sync.where("store_id=#{store_id} and types=#{Sync::SYNC_TYPE[:BUILD]}").order("created_at desc")[0]
    file_time = sync.nil? ? sync_time : sync.sync_at
    dirs=["syncs_datas/","#{file_time.strftime("%Y-%m").to_s}/","#{file_time.strftime("%Y-%m-%d").to_s}/","#{file_time.strftime("%H").to_s}/"]
    dirs.each_with_index {|dir,index| Dir.mkdir path+dirs[0..index].join   unless File.directory? path+dirs[0..index].join }
    begin
      models=get_dir_list("#{Rails.root}/app/models")
      is_update = false
      models.each do |model|
        model_name =model.split(".")[0]
        unless (model_name=="" or Constant::UNNEED_UPDATE.include? model_name)
          cap = eval(model_name.split("_").inject(String.new){|str,name| str + name.capitalize})
          if sync.nil?
            attrs = cap.where("updated_at <= '#{sync_time.strftime("%Y-%m-%d %H")}'")
          else
            attrs = cap.where("updated_at between '#{file_time}' and '#{sync_time.strftime("%Y-%m-%d %H")}'")
          end
          unless attrs.blank?
            is_update = true
            file = File.open("#{path+dirs.join+model_name}.log","w+")
            file.write("#{cap.column_names.join(";||;")}\n\n|::|")
            file.write("#{attrs.inject(String.new) {|str,attr|
              str+attr.attributes.values.join(";||;").gsub(";||;true;||;",";||;1;||;").gsub(";||;false;||;",";||;0;||;")+"\n\n|::|"}}")
            file.close
          end
        end
      end
      if is_update
        filename = input_zip(path+dirs.join,store_id,file_time)
        flog.write("数据更新并压缩成功---#{Time.now}\r\n")
        send_file(store_id,path+dirs.join+filename,filename,file_time)
      end
    rescue
      p "#{filename} file updated failed"
      flog.write("数据更新并压缩失败---#{Time.now}\r\n")
    end
    flog.close
  end

  def self.get_zip_file(flog, obj, time)
    ip_host = Constant::HEAR_OFFICE_IPHOST
    path = Constant::LOCAL_DIR
    arr = obj["zip_name"].split("/")
    read_dirs = ["write_datas/", "#{arr[1]}/", "#{arr[2]}/", "#{arr[3]}/"]
    read_dirs.each_with_index {|dir,index| Dir.mkdir path+read_dirs[0..index].join   unless File.directory? path+read_dirs[0..index].join }
    #Dir.mkdir dirs.join unless File.directory? dirs.join
    file_name = "download.zip"
    is_download = false
    File.open(path+read_dirs.join+file_name, 'wb') do |fo|
      fo.print open(ip_host+obj["zip_name"]).read
      is_download = true
    end
    if is_download
      flog.write("zip文件读取成功---#{time.strftime("%Y-%m-%d %H")}\r\n")
      output_zip(path+read_dirs.join+file_name, flog, time, obj)
    else
      flog.write("zip文件读取失败---#{time.strftime("%Y-%m-%d %H")}\r\n")
    end
  end

  def self.output_zip(path, flog, time, obj)
    is_update = false
    store_id = Store.all.first.id
    begin
      Zip::ZipFile.open(path){ |zipFile|
        zipFile.each do |file|
          if file.name.split(".").reverse[0] =="log"
            contents = zipFile.read(file).split("\n\n|::|")
            titles =contents.delete_at(0).split(";||;")
            contents.delete("\n")
            total_con = []
            cap = eval(file.name.split(".")[0].split("_").inject(String.new){|str,name| str + name.capitalize})
            contents.each do |content|
              hash ={}
              cons = content.split(";||;")
              titles.each_with_index {|title,index| hash[title] = cons[index].nil? ? cons[index] : cons[index].force_encoding("UTF-8")}
              object = cap.new(hash)
              object.id = hash["id"]
              total_con << object
            end
            cap.import total_con, :timestamps=>false, :on_duplicate_key_update=>titles
            is_update = true
          end
        end
      }
    rescue
      flog.write("当前目录文件#{path}更新失败---#{time.strftime("%Y-%m-%d %H")}\r\n")
    end
    Reservation.destroy_all("store_id != #{store_id}")
    Sale.update_all("store_id = #{store_id}")
    MaterialOrder.destroy_all("store_id != #{store_id}")
    if is_update
      Sync.create(:sync_at => obj["sync_at"], :types => Sync::SYNC_TYPE[:SETIN], :zip_name => path)
      flog.write("数据同步成功---#{time.strftime("%Y-%m-%d %H")}\r\n")
    else
      flog.write("数据同步失败---#{time.strftime("%Y-%m-%d %H")}\r\n")
    end
  end

  def self.request_is_generate_zip(time)  #发送请求，看是否已经生成zip文件
    sync = Sync.where("types = #{Sync::SYNC_TYPE[:SETIN]}").order("sync_at desc").first
    if sync.nil?
      url = Constant::HEAD_OFFICE_REQUEST_ZIP
    else
      url = Constant::HEAD_OFFICE_REQUEST_ZIP+"?time=#{sync.sync_at.strftime("%Y-%m-%d %H")}"
    end
    
    Dir.mkdir Constant::LOG_DIR  unless File.directory?  Constant::LOG_DIR
    flog = File.open(Constant::LOG_DIR+"download_and_import_"+time.strftime("%Y-%m").to_s+".log","a+")
    result = Net::HTTP.get(URI.parse(URI.encode(url)))

    if result == "uncomplete"
      flog.write("zip文件还没有生成成功---#{time.strftime("%Y-%m-%d %H")}\r\n")
    else
      objs = JSON.parse(result)
      if !objs.nil?
        objs.each do |obj|
          get_zip_file(flog, obj, time)
        end
      end
    end
  end
  
end