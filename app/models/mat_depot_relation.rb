class MatDepotRelation < ActiveRecord::Base
  belongs_to :material
  belongs_to :depot
end
