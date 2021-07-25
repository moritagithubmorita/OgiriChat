class AddTotalAnswerCountToUser < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :total_answer_count, :integer
  end
end
