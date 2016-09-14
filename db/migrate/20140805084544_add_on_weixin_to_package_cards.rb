class AddOnWeixinToPackageCards < ActiveRecord::Migration
  def change
    rename_column :products,:show_on_ipad,:on_weixin
    change_column :products,:on_weixin,:boolean, :default=>0
    add_column :package_cards, :on_weixin, :boolean, :default=>0
    add_column :sv_cards, :on_weixin, :boolean, :default=>0
    add_column :sales, :on_weixin, :boolean, :default=>0
  end
end
