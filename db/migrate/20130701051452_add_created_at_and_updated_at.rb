class AddCreatedAtAndUpdatedAt < ActiveRecord::Migration
  def change
    add_column :o_pcard_relations, :created_at, :datetime
    add_column :o_pcard_relations, :updated_at, :datetime
  end
end
