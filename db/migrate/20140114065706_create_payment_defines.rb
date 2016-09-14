class CreatePaymentDefines < ActiveRecord::Migration
  def change  #支付方式定义表
    create_table :payment_defines do |t|
      t.string :description
      t.string :status
      t.string :remark
      t.integer :create_staffid  #创建人
      t.timestamps
    end

  end
end
