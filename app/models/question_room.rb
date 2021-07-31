class QuestionRoom < ApplicationRecord
  DEFAULT_GAME_TIME = 120 #デフォルトの対決時間[秒]

  belongs_to :admin, foreign_key: :added_by
  has_many :panelists
  has_many :answers
  has_many :notices

  enum room_status: {standby: 0, matching: 1, running: 2, finished: 3}

  attribute :game_time, :integer, default: DEFAULT_GAME_TIME
  attribute :total_answer_count, :integer, default: 0
  attribute :total_nice_count, :integer, default: 0
  attribute :is_active, :boolean, default: true
  attribute :is_set, :boolean, default: false
  attribute :room_status, :integer, default: :standby
  attribute :panelist_count, :integer, default: 0

  validates :body, :added_by, presence: true

  # 待機状態にさせる
  def get_ready
    # 自身の処理
    self.update(is_active: true, is_set: false, room_status: :standby)
    # 紐づくPanelistを削除
    panelists = Panelist.where(question_room_id: self.id)
    if panelsits.count != 0
      panelists.each do |panelist|
        panelist.destroy()
      end
    end
  end
end
