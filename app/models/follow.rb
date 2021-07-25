class Follow < ApplicationRecord
  belongs_to :user

  validates :user_id, :follow_id, presence: true
end
