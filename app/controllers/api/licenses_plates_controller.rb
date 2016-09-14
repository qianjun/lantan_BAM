#encoding: utf-8
require 'mini_magick'
class Api::LicensesPlatesController < ApplicationController     #车牌识别的图片与XML配置文件同步
  def upload_file   #上传图片或配置文件
    path="#{Rails.root}/public/licenses_plates_folder"
    Dir.mkdir(path) unless File.directory?(path)
    name = params[:img].original_filename
    folder_name = params[:folderName].nil? ? nil : params[:folderName]
    path = path + "/" + folder_name unless folder_name.nil?
    Dir.mkdir(path) unless File.directory?(path)
    msg = name_validate(path, name, 0)
    return msg
  end

  def send_file   #返回图片名或配置文件
    list = []
    path = "#{Rails.root}/public/licenses_plates_folder"
    name = params[:folderName]
    file_type = name.split(".")[1] if name
    if file_type.nil?
      path = path + "/" + name unless name.nil?
      list = Dir.entries(path) if File.directory?(path)
      list.delete(".") if list
      list.delete("..") if list
    elsif file_type == "xml" || file_type == "XML"
      path = path + "/" + name
      list << name if File.exist?(path)
    end
    render :json=>list.to_json
  end

  def name_validate(path, name, i)      #验证文件是否重名
    if File.exist?(path + "/" + name)
      i = i + 1
      n_name = ""
      number = name.split(".")[0].split("_")[1].to_i
      if number==0
        n_name = name.split(".")[0]+"_#{i}"+"."+name.split(".")[1]
      else
        n_name = name.split(".")[0].split("_")[0]+"_#{i}"+"."+name.split(".")[1]
      end
      name_validate(path, n_name, i)
    else
      File.open(path + "/" + name, "wb"){|f| f.write(params[:img].read)}
      a = "success"
      return a
    end
  end

end