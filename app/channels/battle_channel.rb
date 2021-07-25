class BattleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "battle_channel_#{params[:question_room_id]}"
    entered_room
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def entered_room
    ActionCable.server.broadcast "battle_channel_#{params[:question_room_id]}", element: render_element
  end

  def render_element
    return ApplicationController.renderer.render partial: 'public/question_rooms/match_make_user', locals: {user_id: current_user.id }
  end
end
