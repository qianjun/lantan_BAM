class AddGasNumToWorkRecords < ActiveRecord::Migration
  def change
    add_column :work_records, :gas_num, :float
  end
end
