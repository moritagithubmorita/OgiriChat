class CreateNotices < ActiveRecord::Migration[5.2]
  def change
    create_table :notices do |t|
      t.integer :user_id
      t.integer :follow_id
      t.integer :question_room_id
      t.boolean :is_readed

      t.timestamps
    end
  end
end
