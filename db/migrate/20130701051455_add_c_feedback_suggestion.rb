class AddCFeedbackSuggestion < ActiveRecord::Migration
  def change
    add_column :complaints, :c_feedback_suggestion, :boolean #客户反馈意见
  end
end
