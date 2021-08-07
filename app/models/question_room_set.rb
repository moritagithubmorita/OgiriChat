class QuestionRoomSet < ApplicationRecord
  has_many :notices

  validates :question_room1_id, :question_room2_id, :question_room3_id, presence: true
end
