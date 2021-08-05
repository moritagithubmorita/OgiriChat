class CreateQuestionRoomSets < ActiveRecord::Migration[5.2]
  def change
    create_table :question_room_sets do |t|
      t.integer :question_room1_id
      t.integer :question_room2_id
      t.integer :question_room3_id

      t.timestamps
    end
  end
end
