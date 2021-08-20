class Public::HomesController < ApplicationController

  def top
    # 対戦終了画面or対戦詳細画面からトップに戻ってきた場合、ランクアップ表示をする
    # ランクアップは50ナイスごとに行われる。
    if params[:from_follow_modal]=="true"
      if current_user && current_user.rankup_nice_count >= User::RANKUP_NICE_BORDER
        @rankup = "true"
      end
    end

    # binding.pry


  end

  # ランクアップ処理
  def rankup
    # 処理の流れ
    # 1.ランクアップorランクアップ辞退
    # ランクアップする場合は、rankup_nice_countを0にリセットする

    # ランクアップ処理が認可された場合、ランクアップを実行する
    if params[:do_rankup]=="true"
      current_user.update(rank: current_user.rank_before_type_cast+1, rankup_nice_count: 0)
    # ランクアップはしないが、それがベテランー＞マスターへの昇級段階だった場合、以下の処理を行う
    else
      # ランクアップ辞退だが、それがベテラン->マスターへの昇級段階だった場合、star_countを1増やす
      if params[:from_veteran_to_master]=="true"
        current_user.update(star_count: current_user.star_count+1, rankup_nice_count: 0)
      end
    end
  end

  private

  # 全てのテーブルを初期状態に戻す
  # 開始時に存在しないデータは全削除
  # 初期値のあるものを初期化
  def reset_all_tables
    User.all.each do |user|
      user.update(total_nice_count: 0, total_answer_count: 0, rankup_nice_count: 0, star_count: 0, rank: :fledgling)
    end
    Answer.destroy_all
    QuestionRoom.all.each do |qr|
      qr.update(total_nice_count: 0, total_answer_count: 0, is_active: true, is_set: false, room_status: :standby)
    end
    Panelist.destroy_all
    Notice.destroy_all
    Inquiry.destroy_all
    Follow.destroy_all
    Follower.destroy_all
    QuestionRoomSet.destroy_all
    p "Panelist:#{Panelist.count}"
    p "Notice:#{Notice.count}"
    p "Inquiry:#{Inquiry.count}"
    p "Follow:#{Follow.count}"
    p "Follower:#{Follower.count}"
    p "QuestionRoomSet:#{QuestionRoomSet.count}"
  end

end
