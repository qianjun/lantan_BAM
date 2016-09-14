class AddStatusToSvCards < ActiveRecord::Migration
  def change
    add_column :sv_cards, :status, :integer, :default => 1
  end
end
