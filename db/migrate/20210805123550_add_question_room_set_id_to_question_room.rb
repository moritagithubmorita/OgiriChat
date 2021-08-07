class AddQuestionRoomSetIdToQuestionRoom < ActiveRecord::Migration[5.2]
  def change
    add_column :question_rooms, :question_room_set_id, :integer
  end
end
