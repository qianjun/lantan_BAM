class AddAppidToStores < ActiveRecord::Migration
  def change
    add_column :stores, :app_id, :string
    add_column :stores, :app_secret, :string
    add_column :stores,:recommand_prods,:string
  end
end
