class AddRollTologs < ActiveRecord::Migration
  add_column :logs,:roll,:integer,:default=>0
  add_column :logs,:show_index,:integer,:default=>0
end
