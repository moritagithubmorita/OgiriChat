class AnswerChannel < ApplicationCable::Channel
  def subscribed
    stream_from "answer_channel_#{params[:question_room_id]}"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  # 回答を受信してブロードキャストする
  def answer(data)
    # 処理内容
    # 1.Answerインスタンス作成、データベースに保存
    # 2.紐づくQuestionRoomを更新
    # 3.回答をブロードキャスト

    # 回答をデータベースに保存
    a = Answer.new(question_room_id: data['qr_id'], body: data['answer'], user_id: current_user.id)
    a.save

    # 紐づくQuestionRoomを更新
    q = QuestionRoom.find(data['qr_id'])
    q.update(total_answer_count: q.total_answer_count+1)

    # ブロードキャスト
    ActionCable.server.broadcast "answer_channel_#{data['qr_id']}", message: render_message(a)
  end
  
  # その時点までの回答を全てまとめてブロードキャストする
  def get_all_answers(data)
    qr_id = data['qr_id']
    answers = QuestionRoom.find(qr_id).answers.all
    ActionCable.server.broadcast "answer_channel_#{qr_id}", message: render_all_answers_message(answers)
  end

  # 回答テンプレートを返す
  def render_message(answer)
    return ApplicationController.renderer.render partial: 'public/question_rooms/answer', locals: {answer: answer, user: current_user}
  end
  
  # 回答全てを外部テンプレートで返す
  def render_all_answers_message(answers)
    return ApplicationController.renderer.render partial: 'public/question_rooms/answer', collection: answers, as: answer, locals: {user: current_user}
  end

end
