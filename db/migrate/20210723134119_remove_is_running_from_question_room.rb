class RemoveIsRunningFromQuestionRoom < ActiveRecord::Migration[5.2]
  def change
    remove_column :question_rooms, :is_running, :boolean
  end
end
