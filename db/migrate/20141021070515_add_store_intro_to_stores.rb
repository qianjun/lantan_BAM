 class AddStoreIntroToStores < ActiveRecord::Migration
  def change
    add_column :stores, :store_intro, :text
  end
end
