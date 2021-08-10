class Public::HomesController < ApplicationController

  def top
    # 対戦終了画面or対戦詳細画面からトップに戻ってきた場合、ランクアップ表示をする
    # ランクアップは50ナイスごとに行われる。
    if params[:from_finish]==true || params[:from_result]==true
      if current_user && current_user.rankup_nice_count > User::RANKUP_NICE_BORDER
        @rankup = "{\"rankup\":\"true\"}"
      end
    end
  end
  
  private 
  
  def rankup
    # ランクアップ処理が認可された場合、ランクアップを実行する
    if !params[:do_rankup]
      return
    else
      current_user.update(rank: current_user.rank+1, star_count: current_user.star_count+1)
    end
  end

end
