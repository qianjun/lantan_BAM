class ChangeDefaultToPackageCards < ActiveRecord::Migration
   def change
    change_column :package_cards, :prod_point, :integer,:default=>0
  end
end
