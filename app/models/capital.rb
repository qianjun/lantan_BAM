#encoding: utf-8
class Capital < ActiveRecord::Base
  has_many :car_brands

  #获取所有的车品牌/型号
  def self.get_all_brands_and_models
    capitals = Capital.select("id,name").all  #A--Z
    brands = CarBrand.select("id,name,capital_id").all.group_by { |cb| cb.capital_id }  #{A => [<>,<>]}
    capital_arr = []
    car_models = CarModel.select("id,name,car_brand_id").all.group_by { |cm| cm.car_brand_id  }
    (capitals || []).each do |capital|
      c = capital
      brand_arr = []
      c_brands = brands[capital.id] unless brands.empty? and brands[capital.id]
      (c_brands || []).each do |brand|
        b = brand
        b[:models] = car_models[brand.id] unless car_models.empty? and car_models[brand.id] #brand.car_models
        brand_arr << b
      end
      c[:brands] = brand_arr
      capital_arr << c
    end
    capital_arr
  end
end
