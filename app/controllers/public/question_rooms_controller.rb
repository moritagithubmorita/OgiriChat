class Public::QuestionRoomsController < ApplicationController
  skip_before_action :redirected_from_match_make?, only: :battle

  # マッチメイク画面
  def match_make
    # ルーム取得システム
    # 1.まずはマッチング中のルームを検索
    # 2.なければ準備中のルームを検索
    # 3.どちらもなければ「スタンバイ謝罪画面」にリダイレクト
    @question_rooms = QuestionRoom.where(room_status: :matching, is_active: true).limit(3)
    if @question_rooms.nil?
      @question_rooms = QuestionRoom.where(room_status: :standby, is_active: true).limit(3)
      if @question_rooms.nil? || @question_rooms.count < 3
        redirect_to stand_by_path
      end
    end
    @question_rooms = QuestionRoom.all
    #Panelistレコードを生成、dbに保存
    @question_rooms.each do |question_room|
      Panelist.create(question_room_id: question_room.id, user_id: current_user.id)
    end
  end

  def battle
    # 今回使用するお題ルームを3つ再度取得
    panelists = Panelist.where(user_id: current_user.id).limit(3).order("created_at DESC")
    qr1 = QuestionRoom.find(panelists[0].question_room_id)
    qr2 = QuestionRoom.find(panelists[1].question_room_id)
    qr3 = QuestionRoom.find(panelists[2].question_room_id)
    @question_rooms = {qr1: qr1, qr2: qr2, qr3: qr3}
  end

  def finish
  end

  def result
    panelists = Panelist.where(user_id: current_user.id).limit(3).order("created_at DESC")
    qr1 = QuestionRoom.find(panelists[0].question_room_id)
    qr2 = QuestionRoom.find(panelists[1].question_room_id)
    qr3 = QuestionRoom.find(panelists[2].question_room_id)
    @question_rooms = {qr1: qr1, qr2: qr2, qr3: qr3}
  end

end
