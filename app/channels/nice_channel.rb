class NiceChannel < ApplicationCable::Channel
  def subscribed
    stream_from "nice_channel"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # ナイス処理
  # 処理内容
  # 1.ナイスを獲得/取り消しした場合、Answerのtotal_nice_countを+1/-1
  # 2.Answerに紐づくQuestionRoomのtotal_nice_countを更新
  def nice(data)
    a = Answer.find(data['answer_id'])
    q= QuestionRoom.find(data['question_room_id'])
    u = User.find(a.user_id)

    # ナイスが押された場合AnswerとQuestionRoomとログインユーザそれぞれのtotal_nice_countを+1
    if data['is_plus']
      a.update(total_nice_count: a.total_nice_count+1)
      q.update(total_nice_count: q.total_nice_count+1)
      u.update(total_nice_count: u.total_nice_count+1, rankup_nice_count: u.rankup_nice_count+1)
    # ナイスが取り消された場合同じものを-1
    else
      a.update(total_nice_count: a.total_nice_count-1)
      q.update(total_nice_count: q.total_nice_count-1)
      u.update(total_nice_count: u.total_nice_count-1, rankup_nice_count: u.rankup_nice_count-1)
    end
    # ブロードキャスト
    ActionCable.server.broadcast "nice_channel", answer_id: data['answer_id'], total_nice_count: a.total_nice_count
  end

end
