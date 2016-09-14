class AddContentToSvcardUseRecords < ActiveRecord::Migration
  def change
    add_column :svcard_use_records, :content, :string
  end
end
