class CreateCapitals < ActiveRecord::Migration
  def change
    create_table :capitals do |t|
      t.string :name

    end
  end
end
