class QuestionRoomSet < ApplicationRecord
  has_many :notices
  has_many :question_rooms

  validates :question_room1_id, :question_room2_id, :question_room3_id, presence: true
end
