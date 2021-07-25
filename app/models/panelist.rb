class Panelist < ApplicationRecord
  belongs_to :question_room

  validates :question_room_id, presence: true

  attribute :user_id, :integer, default: -1
end
