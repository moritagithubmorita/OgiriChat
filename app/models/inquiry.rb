class Inquiry < ApplicationRecord
  belongs_to :user

  attribute :is_readed, :boolean, default: false
  attribute :is_solved, :boolean, default: false

  validates :user_id, :title, :body, presence: true
end
