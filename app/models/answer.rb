class Answer < ApplicationRecord
  belongs_to :question_room
  belongs_to :user

  attribute :total_nice_count, :integer, default: 0

  validates :question_room_id, :user_id, presence: true
end
