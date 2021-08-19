class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_channel_#{params[:question_room_id]}"

    # デバック。本番でbinding.pryが動くか怪しかったので。
    User.create(name: "ダミー#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}", email: 'dummy@dummy', password: '000000')
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def entered_room(data)
    ActionCable.server.broadcast "room_channel_#{data["question_room_id"]}", message: render_message
  end

  def render_message
    return ApplicationController.renderer.render partial: 'public/question_rooms/match_make_user', locals: {user: current_user, url: ""}
  end
end
