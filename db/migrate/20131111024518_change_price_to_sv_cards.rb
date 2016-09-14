class ChangePriceToSvCards < ActiveRecord::Migration
  change_column :sv_cards, :price, :decimal,{:precision=>"20,2"}
end
