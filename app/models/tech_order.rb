#encoding: utf-8
class TechOrder < ActiveRecord::Base
  include ApplicationHelper
  belongs_to :staff
  belongs_to :order

  
  def self.get_dir_list(path)   #获取目录列表
    list = Dir.entries(path)
    list.delete('.')
    list.delete('..')
    return list
  end

  def self.delete_infos(store_id)
    models = get_dir_list("#{Rails.root}/app/models")
    no_stores = []
    has_stores = []
    models.each do |model|
      model_name =model.split(".")[0]
      unless (model_name=="" or Constant::UNDELETE_UPDATE.include? model_name)
        cap = eval(model_name.split("_").inject(String.new){|str,name| str + name.capitalize})
        if cap.column_names.include? "store_id"
          has_stores << model_name
        else
          no_stores << model_name
        end
      end
    end
    with_stores = no_stores.inject({}) { |h,model|
      cap = eval(model.split("_").inject(String.new){|str,name| str + name.capitalize})
      has_stores.map {|s_model| h[s_model].nil? ? h[s_model]=[model] : h[s_model] << model  if cap.column_names.include?("#{s_model}_id") }
      h
    }
    has_stores.each do |model|
      p model
      cap = eval(model.split("_").inject(String.new){|str,name| str + name.capitalize})
      cap_ids = cap.where(:store_id=>store_id).map(&:id)
      p cap_ids.length
      cap.delete_all(:store_id=>store_id)
      if with_stores[model] && !cap_ids.blank?
        with_stores[model].each {|with_model|
          p with_model
          eval(with_model.split("_").inject(String.new){|str,name| str + name.capitalize}).delete_all("#{model}_id in (#{cap_ids.join(',')})") }
      end
    end
  end
end
