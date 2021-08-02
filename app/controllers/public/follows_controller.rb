class Public::FollowsController < ApplicationController
  # ユーザをフォローする
  def follow
    # フォローモーダルでチェックが入ったユーザを取得
    # なお今回は参戦人数が2人のため、必然的に送られてくるデータは1つ以下

    user_id = params[:user1_id].to_i
    # user_idが取得できた時、そのユーザをフォローする
    if !user_id.nil?
      # フォロー
      Follow.create(user_id: current_user.id, follow_id: user_id)
      # 対象ユーザーのフォロワー(Followerインスタンス)作成
      Follower.create(user_id: user_id, follower_id: current_user.id)
    end

    redirect_to root_path
  end
end
