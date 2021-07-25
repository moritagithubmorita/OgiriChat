class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :notices
  has_many :inquiries
  has_many :answers
  has_many :follows
  has_many :followers

  attribute :is_active, :boolean, default: true
  attribute :total_nice_count, :integer, default: 0
  attribute :total_answer_count, :integer, default: 0

  validates :name, presence: true

end
