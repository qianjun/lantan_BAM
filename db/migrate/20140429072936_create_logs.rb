class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.string :title
      t.text :content
      t.integer :status,:default=>0
      t.integer :store_types, :default=>0 #为0的时候默认是所有门店  其他则为门店的id
      t.timestamps
    end
  end
end
