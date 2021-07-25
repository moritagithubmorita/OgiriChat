class Follower < ApplicationRecord
  belongs_to :user

  validates :user_id, :follower_id, presence: true
end
