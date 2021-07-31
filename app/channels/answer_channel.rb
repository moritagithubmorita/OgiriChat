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
    a = Answer.new(question_room_id: data[:qr_id], body: data[:answer], user_id: current_user.id)
    a.save
    
    # 紐づくQuestionRoomを更新
    q = QuestionRoom.find(data[:qr_id])
    q.update(total_answer_count: q.total_answer_count+1)
    
    # ブロードキャスト
    ActionCable.server.broadcast "answer_channel_#{data[:qr_id]}", message: render_massage(data[:answer], a.id, data[:qr_id])
  end
  
  # 回答テンプレートを返す
  def render_message(answer, answer_id, qr_id)
    return ApplicationController.renderer.render partial: 'public/question_rooms/answer', locals: {answer: answer, answer_id: answer_id, question_room_id: qr_id}
  end

end
