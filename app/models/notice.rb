class Notice < ApplicationRecord
  belongs_to :question_room
  belongs_to :user

  attribute :is_readed, :boolean, default: false

  validates :user_id, :follow_id, :question_room_id, presence: true
end
