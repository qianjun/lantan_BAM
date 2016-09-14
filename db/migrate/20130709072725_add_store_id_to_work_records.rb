class AddStoreIdToWorkRecords < ActiveRecord::Migration
  def change
    add_column :work_records, :store_id, :integer  #添加工作记录的所属门店
  end
end
