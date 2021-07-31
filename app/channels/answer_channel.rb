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
    # 2.回答をブロードキャスト

    # 回答をデータベースに保存
    a = Answer.new(question_room_id: data[:qr_id], body: data[:answer], user_id: current_user.id)
    a.save
    
    # ブロードキャスト
    ActionCable.server.broadcast "answer_channel_#{data[:qr_id]}", message: render_massage(data[:answer])
  end
  
  # 回答テンプレートを返す
  def render_message(answer)
    return ApplicationController.renderer.render partial: 'public/question_rooms/answer', locals: {answer: answer}
  end

end
