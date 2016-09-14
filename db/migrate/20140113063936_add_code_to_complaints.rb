class AddCodeToComplaints < ActiveRecord::Migration
  def change
    add_column :complaints, :code, :string
  end
end
