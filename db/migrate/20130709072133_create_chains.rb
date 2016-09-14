class CreateChains < ActiveRecord::Migration
  def change  #创建连锁店
    create_table :chains do |t|
      t.string :name  #连锁店名称
      t.integer :status #连锁店状态
      t.timestamps
    end
  end
end
