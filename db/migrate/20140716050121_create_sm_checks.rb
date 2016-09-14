class CreateSmChecks < ActiveRecord::Migration
  def change
    create_table :sm_checks do |t|
      t.integer :store_id
      t.integer :sale_id
      t.string :mobilephone
      t.string :open_id
      t.string :valid_code #活动验证码
      t.integer :status #验证是否有效
      t.timestamps
    end
  end
end
