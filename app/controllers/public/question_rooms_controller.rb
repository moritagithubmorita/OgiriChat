class Public::QuestionRoomsController < ApplicationController
  # skip_before_action :redirected_from_match_make?, only: :battle

  before_action :signed_in_check

  def signed_in_check
    if !user_signed_in?
      redirect_to new_user_session_path
    end
  end

  EPOCH = "1970-1-1-0-0-0"  # エポック(UTC)

  # マッチメイク画面
  def match_make
    # <<<処理の流れ>>>
    # 1. 対戦に使うQuestionRoomを3つ取得する。マッチング中->待機中の順に優先して取得する。
    #     -> もし3つ取得できなかったときは「準備中画面」に遷移する。
    # 2. 取得した全ての部屋のroom_statusをmatching、is_setをtrueにする
    # 3. その部屋にすでに他の入室者がいた場合それを取得
    # 4. users取得"後"、QuestionRoom(お題)に紐づくPanelist(回答者)を各お題に対し1つずつ作成。
    # 5. サブスクライブ時に使用するroom_idをhtmlのdata-属性に渡すための文字列を作成

    # マッチング中の部屋を取得。すでに自分が参戦したもの(つまり途中退出した部屋)は除外する
    all_matching_qrs = QuestionRoom.where(room_status: :matching, is_active: true).to_a # 配列にする
    @room_count = all_matching_qrs.length
    logger.debug("match_make#:matchingの数は#{@room_count}")
    # 取得できなかった場合はstandby部屋取得用の処理をする
    if @room_count < 3
      # 特に何もしない
    # 取得できた場合、自身が参加した部屋を除外する処理
    else
      # 除外処理
      all_matching_qrs.delete_if do |mqr|
        mqr.panelists.where(user_id: current_user.id).count>0
      end
      @room_count = all_matching_qrs.length
      logger.debug("除外処理の結果@room_count=#{@room_count}")

      # 3個残らなかった場合次のstandby部屋検索用の処理をする
      if @room_count < 3
        logger.debug("match_make#除外の結果3個未満になってしまいました:matchingの数は#{@room_count}")
      # 3個以上残った場合、先頭から3つをお題に選出する
      else
        logger.debug("match_make#生き残ったmatching部屋の中から3部屋選出します")
        @question_rooms = []
        for cnt in 0..2 do
          @question_rooms.push(all_matching_qrs[cnt])
        end
        @room_count = @question_rooms.length
        logger.debug("match_make#3部屋選出結果:#{@room_count}")
      end
    end

    # 発見した部屋の数が3部屋未満の場合、改めてstandbyを3部屋取得し直す
    if @room_count < 3
      logger.debug("match_make#standbyから3部屋探す")
      @question_rooms = QuestionRoom.where(room_status: :standby, is_active: true).limit(3) # 待機中の部屋を探す
      @room_count = @question_rooms.count #今回発見した部屋の数
      logger.debug("match_make#standbyの数は#{@room_count}")
    end

    # 2回のリクエストにもかかわらず部屋を3部屋取得できなかった場合、準備中画面に遷移
    if @room_count < 3
      logger.debug("match_make#standbyもだめでした:#{@room_count}")
      redirect_to stand_by_path
      return
    end

    # room_statusをmatching、is_setをtrueにする
    @question_rooms.each do |question_room|
      question_room.matching!
      question_room.update(is_set: true)
    end

    # 先に入室しているユーザを取得。1つのデータを取得するだけなのだが、viewでcountを使いたいのでwhereで取得する
    begin
      @users = User.where(id: Panelist.find_by(question_room_id: @question_rooms.first.id).user_id)
    rescue
      @users = User.where(id: -1)  # count==0のための処理。からのRelationを取得(count==0)
    end

    #Panelistレコードを生成、dbに保存
    @question_rooms.each do |question_room|
      Panelist.create(question_room_id: question_room.id, user_id: current_user.id)
    end

    # viewの「data-」属性に今回使うQuestionRoomのidを持たせるための文字列作成
    logger.debug('match_make#qr_idsを作成')
    logger.debug("match_make#@room_count=#{@room_count}")
    count = 1
    qr_ids = "{"
    @question_rooms.each do |question_room|
      qr_ids += "\"qr#{count}_id\":\"#{question_room.id}\""
      count += 1
      if count <= @room_count
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
    #   2.参戦時に作成するdata用文字列(@qr_ids, @qr_bodies)に加え、観覧であることを示す@is_audience = trueおよび開始時間@start_timeを作る

    # 参戦時の処理
    if params[:from_top].nil? && params[:from_notice].nil?
      # 今回使用するお題ルームを3つ再度取得
      @question_rooms = []
      @question_rooms.push(QuestionRoom.find(params[:qr1_id]))
      @question_rooms.push(QuestionRoom.find(params[:qr2_id]))
      @question_rooms.push(QuestionRoom.find(params[:qr3_id]))

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
        @notice = Notice.new(user_id: follower.follower_id, follow_id: current_user.id, question_room_set_id: question_room_set.id)
        @notice.save
      end

    # 観覧時の処理
    else

      qrs = nil # お題セット
      # トップ画面からの場合QuestionRoomSetの取得
      if !params[:from_top].nil?
        # トップ画面から遷移の場合、ここでQuestionRoomSetをランダム取得
        qrs_id = get_question_room_set
        # 取得できなかった場合無効な値をビューに送る
        if qrs_id == -1
          @is_failure = true
          @is_audience="true"
          @start_time="{\"start_time\":\"-1\"}"
          return
        else
          qrs = QuestionRoomSet.find(qrs_id)
        end
      # 通知画面からの遷移の場合QuestionRoomSetを取得
      elsif !params[:from_notice].nil?
        qrs = QuestionRoomSet.find(params[:qrs_id])
      end

      @is_failure=false
      @question_rooms = QuestionRoom.where(id: qrs.question_room1_id).or(QuestionRoom.where(id: qrs.question_room2_id)).or(QuestionRoom.where(id: qrs.question_room3_id))

      # @is_audienceを作成
      # booleanのままで問題ないが、htmlでのdataの表記を揃えたいのであえて文字列にした
      @is_audience = "true"

      # @start_timeを作成
      # created_atを日本時間epochからの経過時間としてミリ秒化
      start_time = milsec_from_epoch_japan(I18n.l(qrs.created_at, format: :hyphen))

      # data用文字列作成
      @start_time = "#{start_time}"

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
    # 1.使用したQuestionRoomのroom_statusをfinishedにする
    # 2.自分以外のpanelistで、かつフォローしてないユーザのidを取得
    # 3.パネリストidを渡すための文字列を作成
    # 4.観覧の場合、それを示す文字列を作成

    # 使用したお題をfinishedにする
    QuestionRoom.find(params[:qr1_id]).finished!
    QuestionRoom.find(params[:qr2_id]).finished!
    QuestionRoom.find(params[:qr3_id]).finished!
    @question_room_ids = {qr1_id: params[:qr1_id], qr2_id: params[:qr2_id], qr3_id: params[:qr3_id]}

    # 参戦した自分以外のpanelistのうち、未フォローのユーザのみ取得
    # 1.ログインユーザ以外の参戦者を全取得
    # 2.ログインユーザがフォロー済みの参戦者を除外する
    # 自分以外の参戦者を全取得
    panelists = QuestionRoom.find(params[:qr1_id]).panelists.where.not(user_id: current_user.id).to_a
    # ログインユーザがフォロー済みの参戦者を除外
    panelists.delete_if do |panelist|
      !(User.find(panelist.user_id).followers.find_by(follower_id: current_user.id).nil?)
    end
    # panelists = QuestionRoom.find(@question_room_ids[:qr1_id].to_i).panelists.where.not(user_id: current_user.id)

    # 文字列作成
    strings = generate_panelist_ids_and_panelist_names_string(panelists)

    @panelist_ids = strings[:panelist_ids]
    @panelist_names = strings[:panelist_names]

    # 観覧の場合dataに渡す文字列を作成
    if params[:is_audience]=="true"
      @is_audience = "true"
    else
      @is_audience = "false"
    end

  end

  def result
    @question_rooms = []
    @question_rooms.push(QuestionRoom.find(params[:qr1_id]))
    @question_rooms.push(QuestionRoom.find(params[:qr2_id]))
    @question_rooms.push(QuestionRoom.find(params[:qr3_id]))

    panelists = QuestionRoom.find(params[:qr1_id]).panelists.where.not(user_id: current_user.id).to_a
    panelists.delete_if do |panelist|
      !(User.find(panelist.user_id).followers.find_by(follower_id: current_user.id).nil?)
    end

    strings = generate_panelist_ids_and_panelist_names_string(panelists)

    @panelist_ids = strings[:panelist_ids]
    @panelist_names = strings[:panelist_names]
  end

  # 回答全てを外部テンプレートで返す
  def get_all_answers_of
    qr_id = params[:qr_id].to_i
    answers = QuestionRoom.find(qr_id).answers.all.order("created_at DESC")
    render partial: 'public/question_rooms/answer', collection: answers, as: 'answer'
  end

  private

  # フォローモーダルのためのカスタムデータ属性用文字列を作成
  # フォロー対象者がいなかった場合は"{}"を返す
  def generate_panelist_ids_and_panelist_names_string(panelists)
    # デバッグ
    logger.debug("question_rooms_controller#finish#panelists.count=#{panelists.count}")

    # 文字列作成
    panelist_ids = "{"
    panelist_names = "{"

    cnt = 1
    panelists.each do |panelist|
      logger.debug("panelist.user_id=#{panelist.user_id}")
      panelist_ids += "\"panelist#{cnt}_id\":\"#{panelist.user_id}\""
      panelist_names += "\"panelist#{cnt}_name\":\"#{User.find(panelist.user_id).name}\""
      cnt += 1
      if cnt <= panelists.count
        panelist_ids += ","
        panelist_names += ","
      end
    end

    panelist_ids += "}"
    panelist_names += "}"

    product = {panelist_ids: panelist_ids, panelist_names: panelist_names}

    return product
  end

  # epoch(japan)からの経過時間[ミリ秒]を返す
  def milsec_from_epoch_japan(y_m_d_h_m_s)
    # y_m_d_h_m_s...年月日時分秒をハイフン区切りの文字列で表したもの

    splited = y_m_d_h_m_s.split('-')

    # 経過秒を計算
    time = Time.new(splited[0].to_i, splited[1].to_i, splited[2].to_i, splited[3].to_i, splited[4].to_i, splited[5].to_i, "+09:00")
    sec_string = time.strftime("%s") # utc基準の経過時間が取れる。timeが日本時間でもutcに変換されて計算されるっぽい
    mil = sec_string.to_i*1000 # ミリ秒に変換

    return mil

  end

  # 観覧用にランダムで対戦中のお題セット(QuestionRoomSet)を取得する
  def get_question_room_set
    qrs_id = -1

    question_rooms_array = QuestionRoom.where(room_status: :running).to_a
    if question_rooms_array.length==0
      return -1
    end

    # 取得した対戦中のお題部屋から、ログインユーザが参戦しているものを除外
    question_rooms_array.delete_if do |qr|
      qr.panelists.where(user_id: current_user.id).count>0
    end

    if question_rooms_array.length==0
      return -1
    end

    random = Random.rand(0..question_rooms_array.length-1)
    qr = question_rooms_array[random]
    begin qrs_id=QuestionRoomSet.find_by(question_room1_id: qr.id).id
    rescue
      begin qrs_id=QuestionRoomSet.find_by(question_room2_id: qr.id).id
      rescue
        begin qrs_id=QuestionRoomSet.find_by(question_room3_id: qr.id).id
        rescue
          qrs_id = -1
        end
      end
    end

    return qrs_id

  end

end
