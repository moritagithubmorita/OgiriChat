class Public::NoticesController < ApplicationController
  before_action :signed_in_check

  # 一覧表示
  def index
    # 処理内容
    # ・通知を上から新着順に表示する
    # ・全てが表示されたタイミングで全通知を既読(is_readed: true)にする
    @notices = current_user.notices.order("created_at DESC")
    @notices.each do |n|
      n.update(is_readed: true)
    end
  end

  private

  def signed_in_check
    if !user_signed_in?
      redirect_to new_user_session_path
    end
  end

end
