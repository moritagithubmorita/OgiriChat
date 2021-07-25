class Public::QuestionRoomsController < ApplicationController
  skip_before_action :redirected_from_match_make?, only: :battle
  
  # マッチメイク画面
  def match_make
    # ルーム取得システム
    # 1.まずはマッチング中のルームを検索
    # 2.なければ準備中のルームを検索
    # 3.どちらもなければ「スタンバイ謝罪画面」にリダイレクト
    @question_room = QuestionRoom.find_by(room_status: :matching)
    if @question_room.nil?
      @question_room = QuestionRoom.find_by(room_ststus: :standby)
      if @question_room.nil?
        redirect_to stand_by_path
      end
    end
    #Panelistレコードを生成、dbに保存
    Panelist.create(question_room_id: @question_room.id, user_id: current_user.id)
  end
  
  def battle
  end

end
