class Depot < ActiveRecord::Base
  belongs_to :store
  PerPage = 10
end
