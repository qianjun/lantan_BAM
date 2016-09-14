class AddDescriptionToSvCards < ActiveRecord::Migration
  def change
    add_column :sv_cards, :description, :string
  end
end
