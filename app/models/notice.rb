class Notice < ApplicationRecord
  belongs_to :user
  belongs_to :question_room_set

  attribute :is_readed, :boolean, default: false

  validates :user_id, :follow_id, :question_room_set_id, presence: true
end
