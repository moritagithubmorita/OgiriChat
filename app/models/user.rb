class User < ApplicationRecord
  RANKUP_NICE_BORDER = 50 # ランクアップに必要なniceの数(全ランク)
  
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :notices
  has_many :inquiries
  has_many :answers
  has_many :follows
  has_many :followers

  enum rank: {fledgling: 0, seeker: 1, skilful: 2, veteran: 3, master: 4}

  attribute :is_active, :boolean, default: true
  attribute :total_nice_count, :integer, default: 0
  attribute :total_answer_count, :integer, default: 0
  attribute :star_count, :integer, default: 0
  attribute :rank, :integer, default: :fledgling
  attribute :rankup_nice_count, :integer, default: 0

  validates :name, presence: true

end
