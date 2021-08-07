class Public::QuestionRoomsController < ApplicationController
  skip_before_action :redirected_from_match_make?, only: :battle

  EPOCH = "1970-1-1-0-0-0"  # エポック(UTC)

  # マッチメイク画面
  def match_make
    # 処理の流れ
    # 1. 対戦に使うQuestionRoomを3つ取得する。マッチング中>待機中の順に優先して取得する。
    #     -> もし3つ取得できなかったときは「準備中画面」に遷移する。
    # 2. 取得した全ての部屋のroom_statusをmatchingにする
    # 3. その部屋にすでに他の入室者がいた場合それを取得
    # 4. users取得"後"、QuestionRoom(お題)に紐づくPanelist(回答者)をそれぞれに対し1つずつ作成。
    # 5. サブスクライブ時に使用するroom_idをhtmlのdata-属性に渡すための文字列を作成

    product = QuestionRoom.where(room_status: :matching, is_active: true,).limit(3)  # マッチング中の部屋を探す
    room_count = product.count
    # 発見した部屋の数が3部屋未満の場合、改めてstandbyを3部屋取得し直す
    if room_count < 3
      product = QuestionRoom.where(room_status: :standby, is_active: true).limit(3) # 待機中の部屋を探す
      room_count = product.count #今回発見した部屋の数
    end
    # 部屋を3部屋取得できなかった場合、準備中画面に遷移
    if room_count != 3
      redirect_to stand_by_path
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
    #   2.参戦時に作成するdata用文字列(@qr_ids, @qr_bodies)に加え、観覧であることを示す@is_audience = trueおよび開始時間@start_timeを作る


    # 参戦時の処理
    if params[:qrs_id].nil?
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
        @notice = Notice.new(user_id: follower.follower_id, follow_id: current_user.id, question_room_set_id: question_room_set.id)
        @notice.save
      end

    # 観覧時の処理
    else
      qrs = nil # 今回使うお題セット
      
      # トップ画面から遷移の場合、ここでQuestionRoomSetをランダム取得
      qrs_id = get_question_room_set
      # 取得できなかった場合無効な値をビューに送る
      if qrs_id == -1
        @question_rooms=nil
        @is_audience='true'
        @start_time="{\"start_time\":\"-1\"}"
        return
      else
        qrs = QuestionRoomSet.find(qrs_id)
      end
      
      # 今回使用するお題を取得
      if params[:from_top] != true
        qrs = QuestionRoomSet.find(params[:qrs_id])
      end
      @question_rooms = QuestionRoom.where(id: qrs.question_room1_id).or(QuestionRoom.where(id: qrs.question_room2_id)).or(QuestionRoom.where(id: qrs.question_room3_id))

      # @is_audienceを作成
      # booleanのままで問題ないが、htmlでのdataの表記を揃えたいのであえて文字列にした
      @is_audience = 'true'

      # @start_timeを作成
      # 処理の流れ
      # 0.事前準備(定数の準備など)
      # 1.0年をスタートにcreated_at(日本時間)をミリ秒化(UTC)
      # 2.0年をスタートにepochをミリ秒化(UTC)
      # 3.epochからcreated_atまでの経過時間を1-2により求め、文字列作成
      # 4.dataに渡す

      # created_atをミリ秒化
      # 1.UTCに変換
      qrs_created_utc = translate_from_japan_to_utc(I18n.l(qrs.created_at, format: :hyphen))
      # 2.0年からのミリ秒に変換
      qrs_created_milsec = milsec_from_0(qrs_created_utc)

      # epochをミリ秒化
      epoch_milsec = milsec_from_0(EPOCH)

      # epochからcrated_atまでの経過時間を算出
      start_time = qrs_created_milsec-epoch_milsec

      # data用文字列作成
      @start_time = "{\"start_time\":\"#{start_time}\"}"


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

  # 指定期間内の閏年の数を求める
  def how_many_leap_years(from, to)
    # <概要>
    # ・西暦(integer)で指定された期間内に閏年が何個あるか返却する
    # ・from、toも判定に含める
    # ・from...開始年
    # ・to...終了年
    # <閏年の定義>
    # 「100の倍数かつ400の倍数でない」でない4の倍数全てを閏年という。
    # <計算の流れ>
    # 1.0年からfrom-1年までの閏年個数を算出
    # 2.0年からto年までの閏年個数を算出
    # 3.2から1を引く

    # 0からfrom-1までの閏年数を計算
    from_4 = (from-1)/4 # from-1までの4の倍数の個数
    from_100 = (from-1)/100 # from-1までの100の倍数の個数
    from_400 = (from-1)/400 # from-1までの400の倍数個数
    # 「4の倍数の個数」 - 「100の倍数かつ400の倍数でない」個数 = 閏年の個数
    from_leap = from_4 - (from_100 - from_400)

    # 0からtoまでの閏年数を計算
    to_4 = to/4
    to_100 = to/100
    to_400 = to/400
    to_leap = to_4-(to_100-to_400)

    # fromからtoまでの閏年数を計算
    leap = to_leap - from_leap

    return leap
  end

  # yearが閏年か判定
  def is_leap_year?(year)
    # 閏年の定義
    # 「"100の倍数であり400の倍数でない"ものを除く全ての4の倍数」
    if year%4 != 0
      return false
    else
      if year%100==0 && year%400!=0
        return false
      end
      return true
    end
  end

  # 0年からの経過時間[ミリ秒]を返す
  def milsec_from_0(y_m_d_h_m_s)
    # UTC時間の0年1月0日0時0分0秒を基準とする
    # y_m_d_h_m_s...年月日時分秒をハイフン区切りの文字列で表したもの

    second_mil = 1000           # 秒のミリ秒
    minute_mil = 60*second_mil  # 分のミリ秒
    hour_mil = 60*minute_mil    # 時のミリ秒
    date_mil = 24*hour_mil      # 日のミリ秒
    month__135781012mil = date_mil*31  # 31日月のミリ秒
    month_46911_mil = date_mil*30  # 30日月のミリ秒
    month_2_mil = date_mil*28 # 2月(平年)のミリ秒
    month_2_leap_mil = month_2_mil + date_mil # 2月(閏年)のミリ秒
    year_mil = 365*date_mil     # 平年のミリ秒
    leap_year_mil = year_mil + date_mil # 閏年のミリ秒

    splited = y_m_d_h_m_s.split('-')
    leap_count = how_many_leap_years(0, splited[0].to_i-1)  # 引数の前年までの閏年の数
    is_leap = is_leap_year?(splited[0].to_1)  # 引数が閏年か判定
    year = (splited[0].to_i-1-c_leap)*year_mil + leap_count*leap_year_mil # 年
    month = 0                                                             # 月
    for month in 1..12 do
      if month >= splited[1].to_i
        break
      else
        case month
        when 4,6,9,11 then
          month += month_46911_mil
        when 1,3,5,7,8,10,12 then
          month += month__135781012mil
        when 2 then
          if is_leap
            month += month_2_leap_mil
          else
            month += month_2_mil
          end
        end
      end
    end
    date = splited[2].to_i*date_mil                                       # 日
    hour = splited[3].to_i*hour_mil                                       # 時間
    minute = splited[4].to_i*minute_mil                                   # 分
    second = splited[5].to_i*second_mil                                   # 秒
    # 合計(計算終了)
    mil = year+month+date+hour+minute+second

    return mil
  end

  # 日本時間をUTCに変換
  def translate_from_japan_to_utc(y_m_d_h_m_s)
    # ・時差9時間を引くだけ
    # ・文字列を返す

    # 各時間要素に分割
    splited = y_m_d_h_m_s.split('-')
    # 0...年
    # 1...月
    # 2...日
    # 3...時

    year = splited[0].to_i
    month = splited[1].to_i
    date = splited[2].to_i

    hour = splited[3].to_i-9
    if hour<0
      hour = 24+hour
      date = date-1
      if date == 0
        case month-1
        when 4,6,9,11 then
          date = 30
        when 1,3,5,7,8,10,12 then
          date = 31
        when 2 then
          if is_leap_year?(year)
            date = 29
          else
            date = 28
          end
        when 0 then
          date = 31
          month = 12
          year = year-1
        end
      end
    end

    utc = year+"-"+month+"-"+date+"-"+hour+"-"+splited[4]+"-"+splited[5]

    return utc
  end
  
  # 観覧用にランダムで対戦中のお題セット(QuestionRoomSet)を取得する
  def get_question_room_set
    qrs_id = -1
    
    question_rooms_array = QuestionRoom.where(room_status: :running).to_a
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
