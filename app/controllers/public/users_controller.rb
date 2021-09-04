class Public::UsersController < ApplicationController
  before_action :signed_in_check

  def signed_in_check
    if !user_signed_in?
      redirect_to new_user_session_path
    end
  end

  def show
    @user = current_user

    # ログインユーザがフォローしているユーザを渡す
    @follows = current_user.follows.all
  end

  def edit
    @user = current_user

    # ログインユーザのランク以下のrankの「キーのみ」が含まれる"配列"を作成
    # enum_helperを使用するために、ハッシュではなく配列
    @rank_keys = []
    ranks = User.ranks # rankカラムの値をハッシュで全取得
    ranks.each do |k, v|
      if v<=@user.rank_before_type_cast
        @rank_keys.push(k)
      end
    end
  end

  def update
    if current_user.update(user_params)
      redirect_to users_path
    else
      @user = User.new(user_params)
      render :edit
    end
  end

  # 退会確認
  def confirm
  end

  # 退会処理
  def withdraw
    current_user.update(is_active: false)
    sign_out current_user
    redirect_to root_path
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :rank)
  end

end
