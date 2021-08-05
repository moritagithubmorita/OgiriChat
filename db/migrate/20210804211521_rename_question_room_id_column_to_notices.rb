class RenameQuestionRoomIdColumnToNotices < ActiveRecord::Migration[5.2]
  def change
    rename_column :notices, :question_room_id, :question_room_set_id
  end
end
