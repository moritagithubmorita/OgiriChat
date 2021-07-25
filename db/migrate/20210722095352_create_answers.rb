class CreateAnswers < ActiveRecord::Migration[5.2]
  def change
    create_table :answers do |t|
      t.integer :question_room_id
      t.integer :user_id
      t.integer :total_nice_count

      t.timestamps
    end
  end
end
