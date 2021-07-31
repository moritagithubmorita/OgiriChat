class Public::QuestionRoomsController < ApplicationController
  skip_before_action :redirected_from_match_make?, only: :battle

  # マッチメイク画面
  def match_make
    # 処理の流れ
    # 1. 対戦に使うQuestionRoomを3つ取得する。マッチング中>待機中の順に優先して取得する。
    #     -> もし3つ取得できなかったときは「準備中画面」に遷移する。
    # 2. 取得した全ての部屋のroom_statusをmatchingにする
    # 3. その部屋にすでに他の入室者がいた場合それを取得
    # 4. users取得"後"、QuestionRoom(お題)に紐づくPanelist(回答者)をそれぞれに対し1つずつ作成。
    # 5. サブスクライブ時に使用するroom_idをhtmlのdata-属性に渡すための文字列を作成

    product = question_rooms1 = QuestionRoom.where(room_status: :matching, is_active: true, panelist_count: 1).limit(3)  # マッチング中の部屋を探す
    qr1_count = question_rooms1.count # 発見した部屋の数
    # 発見した部屋の数が3部屋未満の場合、足りない分を待機中の部屋から探す
    if qr1_count < 3
      question_rooms2 = QuestionRoom.where(room_status: :standby, is_active: true).limit(3-qr1_count) # 待機中の部屋を探す
      qr2_count = question_rooms2.count #今回発見した部屋の数
      # 2回の部屋取得数の合計が3部屋未満の場合、発見失敗ー＞「準備中画面」へ遷移
      if (qr1_count+qr2_count) < 3
        redirect_to stand_by_path
      end
      # 2回の部屋取得の結果3部屋揃った場合、取得した部屋を一つにまとめ、(Relationをor関数でまとめる)ビューへ渡す
      product = question_rooms1.or(question_rooms2)
    end
    # 取得したマッチング中の部屋3部屋をマッチングビューに渡す
    @question_rooms = product

    # room_statusをmatchingにする
    @question_rooms.each do |question_room|
      question_room.matching!
    end

    # 先に入室しているユーザを取得。1つのデータを取得するだけなのだが、viewでcountを使いたいのでwhereで取得する
    begin
      @users = User.where(id: Panelist.find_by(question_room_id: @question_rooms.first.id).user_id)
    rescue
      @users = User.where(id: -1)  # count==0のための処理
    end

    #Panelistレコードを生成、dbに保存
    @question_rooms.each do |question_room|
      Panelist.create(question_room_id: question_room.id, user_id: current_user.id)
      # 紐づくQuestionRoomのpanelist_countを+1
      question_room.update(panelist_count: question_room.panelist_count+1)
    end

    # viewの「data-」属性に今回使うQuestionRoomのidを持たせるための文字列作成
    count = 1
    qr_ids = "{"
    @question_rooms.each do |question_room|
      qr_ids += "\"qr#{count}_id\":\"#{question_room.id}\""
      count += 1
      if count <= @question_rooms.count
        qr_ids += ","
      end
    end
    qr_ids += "}"
    @qr_ids = qr_ids

  end

  def battle
    # 今回使用するお題ルームを3つ再度取得
    qr1 = QuestionRoom.find(params[:qr1_id])
    qr2 = QuestionRoom.find(params[:qr2_id])
    qr3 = QuestionRoom.find(params[:qr3_id])
    @question_rooms = {qr1: qr1, qr2: qr2, qr3: qr3}

    # 使用するお題(question_rooms)のroom_statusをrunningにする
    @question_rooms.each do |key, value|
      value.running!
    end

    # viewの「data-」属性に今回使うQuestionRoomのidを持たせるための文字列作成
    count = 1
    qr_ids = "{"
    @question_rooms.each do |key, value|
      qr_ids += "\"qr#{count}_id\":\"#{value}\""
      count += 1
      if count <= @question_rooms.count
        qr_ids += ","
      end
    end
    qr_ids += "}"
    @qr_ids = qr_ids
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
