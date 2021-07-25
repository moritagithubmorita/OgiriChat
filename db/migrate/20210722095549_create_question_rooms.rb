class CreateQuestionRooms < ActiveRecord::Migration[5.2]
  def change
    create_table :question_rooms do |t|
      t.string :body
      t.integer :added_by
      t.integer :game_time
      t.integer :total_answer_count
      t.integer :total_nice_count
      t.boolean :is_active
      t.boolean :is_set
      t.boolean :is_running

      t.timestamps
    end
  end
end
