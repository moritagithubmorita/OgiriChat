class AddPanelistCountToQuestionRoom < ActiveRecord::Migration[5.2]
  def change
    add_column :question_rooms, :panelist_count, :integer
  end
end
