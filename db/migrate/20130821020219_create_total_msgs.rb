class CreateTotalMsgs < ActiveRecord::Migration
  def change
    create_table :total_msgs do |t|
      t.string :shop
      t.integer :msgnum
      t.text :msg1
      t.text :msg2
      t.text :msg3
      t.text :msg4
      t.text :msg5
      t.text :msg6
      t.text :msg7
      t.text :msg8
      t.text :msg9
      t.text :msg10
      t.text :msg11
      t.text :msg12
      t.text :msg13
      t.text :msg14
      t.text :msg15
      t.text :msg16
      t.text :msg17
      t.text :msg18
      t.text :msg19
      t.text :msg20
      t.text :msg21
      t.text :msg22
      t.text :msg23
      t.text :msg24
      t.text :msg25
      t.text :msg26
      t.text :msg27
      t.text :msg28
      t.text :msg29
      t.text :msg30

      t.timestamps
    end
  end
end
