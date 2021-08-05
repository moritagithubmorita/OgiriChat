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

    product = question_rooms1 = QuestionRoom.where(room_status: :matching, is_active: true,).limit(3)  # マッチング中の部屋を探す
    qr1_count = question_rooms1.count # 発見した部屋の数
    # 発見した部屋の数が3部屋未満の場合、足りない分を待機中の部屋から探す
    if qr1_count < 3
      question_rooms2 = QuestionRoom.where(room_status: :standby, is_active: true).limit(3-qr1_count) # 待機中の部屋を探す
      qr2_count = question_rooms2.count #今回発見した部屋の数
      # 2回の部屋取得数の合計が3部屋未満の場合、発見失敗ー＞「準備中画面」へ遷移
      if (qr1_count+qr2_count) != 3
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
    # <基本処理>
    # お題を取得し、room_statusをrunning(対戦中)に変更
    # ログインユーザのフォロワーに参戦通知を送る(Noticeレコード作成)
    # カスタムデータ属性(jsで使う)に渡す値を文字列で作成
    # 
    # <観覧時の処理>
    # @処理概要
    #   ・params[:qrs_id]がnilじゃなければ「観覧」であるとする。
    #   ・その際params[:qrs_id]には"通知(notice)に含めた"or"ランダムに取得した"お題セットのidが入っている
    # @処理の流れ
    #   1.paramsで渡ってきたお題セットを取得し、@question_roomsに収納
    #   2.参戦時に作成するdata用文字列(@qr_ids, @qr_bodies)に加え、観覧であることを示す@is_audience = trueを作る
    
    
    # 参戦時の処理
    if params[:qrs_id]==nil
      # 今回使用するお題ルームを3つ再度取得
      qr1 = QuestionRoom.where(id: params[:qr1_id])
      qr2 = QuestionRoom.where(id: params[:qr2_id])
      qr3 = QuestionRoom.where(id: params[:qr3_id])
      @question_rooms = qr1.or(qr2).or(qr3)
  
      # 使用するお題(question_rooms)のroom_statusをrunningにする
      @question_rooms.each do |question_room|
        question_room.running!
      end
      
      # 通知をフォロワーに送る
      # お題セットの作成
      question_room_set = QuestionRoomSet.new()
      cnt = 1
      @question_rooms.each do |question_room|
        if cnt==1
          question_room_set.question_room1_id=question_room.id
        elsif cnt==2
          question_room_set.question_room2_id=question_room.id
        else
          question_room_set.question_room3_id=question_room.id
        end
        cnt+=1
      end
      question_room_set.save
      # 通知に含め、フォロワーに送る
      current_user.followers.all.each do |follower|
        notice = Notice.new(user_id: follower.id, follow_id: current_user.id, question_room_set_id: question_room_set.id)
        notice.save
      end
      
    # 観覧時の処理
    else
      # 今回使用するお題を取得
      qrs = QuestionRoomSet.find(params[:qrs_id])
      qr1 = QuestionRoom.where(id: qrs.question_room1_id)
      qr2 = QuestionRoom.where(id: qrs.question_room2_id)
      qr3 = QuestionRoom.where(id: qrs.question_room3_id)
      @question_rooms = qr1.or(qr2).or(qr3)
      
      # @is_audienceを作成
      # booleanのままで問題ないが、htmlでのdataの表記を揃えたいのであえて文字列にした
      @is_audience = 'true'
    end

    # viewの「data-」属性に今回使うQuestionRoomのidを持たせるための文字列作成
    count = 1
    qr_ids = "{"
    qr_bodies = "{"
    @question_rooms.each do |question_room|
      qr_ids += "\"qr#{count}_id\":\"#{question_room.id}\""
      qr_bodies += "\"qr#{count}_body\":\"#{question_room.body}\""
      count += 1
      if count <= @question_rooms.count
        qr_ids += ","
        qr_bodies += ","
      end
    end
    qr_ids += "}"
    qr_bodies += "}"
    @qr_ids = qr_ids
    @qr_bodies = qr_bodies
  end

  def finish
    # 処理内容
    # 1.自分以外のpanelistで、かつフォローしてないユーザのidを取得
    # 2.パネリストidを渡すための文字列を作成
    # 3.観覧の場合、それを示す文字列を作成

    # 参戦した自分以外のpanelistのうち、未フォローのユーザのみ取得
    @question_room_ids = {qr1_id: params[:qr1_id], qr2_id: params[:qr2_id], qr3_id: params[:qr3_id]}
    panelists = QuestionRoom.find(@question_room_ids[:qr1_id].to_i).panelists.where.not(user_id: current_user.id)

    # 文字列作成
    strings = generate_panelist_ids_and_panelist_names_string(panelists)

    @panelist_ids = strings[:panelist_ids]
    @panelist_names = strings[:panelist_names]
    
    # 観覧の場合dataに渡す文字列を作成
    if params[:is_audience]==true
      @is_audience = "true"
    else
      @is_audience = "false"
    end

  end

  def result
    qr1 = QuestionRoom.where(id: params[:qr1_id].to_i)
    qr2 = QuestionRoom.where(id: params[:qr2_id].to_i)
    qr3 = QuestionRoom.where(id: params[:qr3_id].to_i)
    @question_rooms = qr1.or(qr2).or(qr3)

    panelists = @question_rooms.first.panelists.where.not(user_id: current_user)

    strings = generate_panelist_ids_and_panelist_names_string(panelists)

    @panelist_ids = strings[:panelist_ids]
    @panelist_names = strings[:panelist_names]
  end

  private

  # フォローモーダルのためのカスタムデータ属性用文字列を作成
  # フォロー対象者がいなかった場合は"{}"を返す
  def generate_panelist_ids_and_panelist_names_string(panelists)
    # 文字列作成
    panelist_ids = "{"
    panelist_names = "{"
    cnt = 1
    panelists.each do |panelist|
      # panelistをフォロー済みの場合はフォロー確認の対象から外す(ハッシュに加えない)
      if User.find(panelist.user_id).followers.find_by(follower_id: current_user.id).nil?
      # 未フォローの場合、フォロー確認の対象とする(ハッシュに加えビューに渡す)
        panelist_ids += "\"panelist#{cnt}_id\":\"#{panelist.user_id}\""
        panelist_names += "\"panelist#{cnt}_name\":\"#{User.find(panelist.user_id).name}\""
        cnt += 1
        if cnt <= panelists.count
          panelist_ids += ","
          panelist_names += ","
        end
      end
    end
    panelist_ids += "}"
    panelist_names += "}"

    product = {panelist_ids: panelist_ids, panelist_names: panelist_names}

    return product
  end

end
