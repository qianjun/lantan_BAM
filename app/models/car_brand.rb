class CarBrand < ActiveRecord::Base
  belongs_to :capital
  has_many :car_models

  def self.get_brand_by_capital(capital_id)
    CarBrand.find_all_by_capital_id(capital_id).to_json
  end



  
end
