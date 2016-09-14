class AddAttendTypesToWorkRecords < ActiveRecord::Migration
  def change
    add_column :work_records, :attend_types, :integer,:default=>0
  end
end
