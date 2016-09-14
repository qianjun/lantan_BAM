class AddStoreIdAndUseRangeToSvCards < ActiveRecord::Migration
  def change
    add_column :sv_cards, :store_id, :integer
    add_column :sv_cards, :use_range, :integer    #优惠卡使用范围
  end
end
