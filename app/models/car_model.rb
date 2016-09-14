class CarModel < ActiveRecord::Base
  belongs_to :car_brand
  has_many :car_nums

  def CarModel.get_model_by_brand(brand_id)
    CarModel.find_all_by_car_brand_id(brand_id).to_json
  end
  
end
