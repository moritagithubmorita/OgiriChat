class CreatePanelists < ActiveRecord::Migration[5.2]
  def change
    create_table :panelists do |t|
      t.integer :question_room_id
      t.integer :user_id

      t.timestamps
    end
  end
end
