class AddPriceToBackGoodRecords < ActiveRecord::Migration
  def change
    add_column :back_good_records, :price, :decimal,:default=>0,:precision=>"20,2"
  end
end
