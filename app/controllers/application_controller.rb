class ApplicationController < ActionController::Base
  # マッチメイク画面から対戦に行かなかった場合(不正)の処理。
  # public/question_rooms#battleのみskipする(正規のルート故)
  # before_action :redirected_from_match_make?

  # devise
  before_action :configure_permitted_parameters, if: :devise_controller?

  # マッチメイク画面から対戦画面以外に遷移した時(予定外)の処理
  # 処理内容
  # QuestionRoomおよびそれに紐づくPanelistを削除
  # def redirected_from_match_make?
  #   if request.referer&.include?("/question_rooms/match_make")
  #     panelists = Panelist.where(user_id: current_user.id).order(updated_at: "DESC").limit(3)  # current_userの最新のpanelistを取得
  #     panelists.each do |panelist|
  #       question_room = QuestionRoom.find(panelist.question_room_id)  #QuestionRoom取得
  #       question_room.get_ready() #待機状態に戻す。紐づくPanelistsも適切な処理(削除)をされる
  #     end
  #   end
  # end

  protected

  # サインアップで名前を登録できるようにする記述。
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys:[:name])
  end
end
