class CreateAlipayRecords < ActiveRecord::Migration
  def change
    create_table :alipay_records do |t|
      t.decimal :pay_price,{:precision=>"10,2",:default=>0}
      t.integer :pay_types,:default=>1
      t.integer :pay_status,:default=>0
      t.decimal :left_price,{:precision=>"10,2",:default=>0}
      t.string  :alipay_records, :out_trade_no
      t.string  :pay_email
      t.string  :pay_userid
      t.integer :store_id
      t.timestamps
    end
  end
end
