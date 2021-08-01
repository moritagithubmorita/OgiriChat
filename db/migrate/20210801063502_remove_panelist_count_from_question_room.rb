class RemovePanelistCountFromQuestionRoom < ActiveRecord::Migration[5.2]
  def change
    remove_column :question_rooms, :panelist_count, :integer
  end
end
