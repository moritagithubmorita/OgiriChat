class RoomChannel < ApplicationCable::Channel
  def subscribed
    stream_from "room_channel_#{params[:question_room_id]}"
    console.log("subscribed")
    entered_room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def entered_room
    ActionCable.server.broadcast "room_channel_#{params[:question_room_id]}", message: render_message
  end

  def render_message
    return ApplicationController.renderer.render partial: 'public/question_rooms/match_make_user', locals: {user: current_user }
  end
end
