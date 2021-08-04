class Public::FollowsController < ApplicationController
  # ユーザをフォローする
  def follow
    # フォローモーダルでチェックが入ったユーザを取得
    # なお今回は参戦人数が2人のため、必然的に送られてくるデータは1つ以下

    # フォローモーダルのチェックボックスにチェックが入った場合フォローする
    # フォロワーとフォローをそれぞれ1つずつ作る
    if params[:user1_flag]=="on"
      # フォロー
      Follow.create(user_id: current_user.id, follow_id: params[:user1_id].to_i)
      # 対象ユーザーのフォロワー(Followerインスタンス)作成
      Follower.create(user_id: params[:user1_id].to_i, follower_id: current_user.id)
    end

    redirect_to root_path
  end

  # フォロー済みユーザをフォロー解除/再フォローする(マイページ用の関数)
  def toggle
    the_other_id = params[:the_other_id].to_i

    # フォローしていた場合フォローを外し、対象者のフォロワーテーブルからログインユーザのデータを削除する
    begin current_user.follows.find_by(follow_id: the_other_id)
      Follow.find_by(follow_id: the_other_id, user_id: current_user.id).destroy
      Follower.find_by(user_id: the_other_id, follower_id: current_user.id).destroy
    # フォローしてなかった場合フォローし、対象者のフォロワーとしてログインユーザを登録する
    rescue
      Follow.create(follow_id: the_other_id, user_id: current_user.id)
      Follower.create(user_id: the_other_id, follower_id: current_user.id)
    end
  end
end
