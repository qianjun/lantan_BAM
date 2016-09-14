class AddStoreIdToBackGoodRecords < ActiveRecord::Migration
  def change
    add_column :back_good_records, :store_id, :integer
  end
end
