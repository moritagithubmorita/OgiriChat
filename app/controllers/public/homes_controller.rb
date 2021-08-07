class Public::HomesController < ApplicationController

  def top
    # 対戦終了画面or対戦詳細画面からトップに戻ってきた場合、ランクアップ表示をする
    # ランクアップは50ナイスごとに行われる。
    if params[:from_finish]==true || params[:from_result]==true
      if current_user.rankup_nice_count > User::RANKUP_NICE_BORDER
        @rankup = "{\"rankup\":\"true\"}"
      end
    end
      
      
      
      
      
  end

end
