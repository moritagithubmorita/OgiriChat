class AddRoomStatusToQuestionRoom < ActiveRecord::Migration[5.2]
  def change
    add_column :question_rooms, :room_status, :integer
  end
end
