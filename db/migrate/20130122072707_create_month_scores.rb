class CreateMonthScores < ActiveRecord::Migration
  def change
    create_table :month_scores do |t|
      t.integer :sys_score  #系统打分
      t.integer :manage_score  #主管打分
      t.integer :current_month  #当前月份
      t.boolean :is_syss_update #系统分数是否被更改
      t.integer :staff_id
      t.string :reason    #原因
      t.timestamps
    end

    add_index :month_scores, :sys_score
    add_index :month_scores, :manage_score
    add_index :month_scores, :current_month
    add_index :month_scores, :staff_id    
  end
end
