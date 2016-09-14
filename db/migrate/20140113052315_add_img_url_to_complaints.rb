class AddImgUrlToComplaints < ActiveRecord::Migration
  def change
    add_column :complaints, :img_url, :string
  end
end
