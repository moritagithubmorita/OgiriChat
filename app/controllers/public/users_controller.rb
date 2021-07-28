class Public::UsersController < ApplicationController
  def show
    @user = current_user
  end

  def edit
    @user = current_user

    # ログインユーザのランク以下のrankのみ含まれるハッシュを作成
    @ranks = {}
    ranks = User.ranks # rankカラムの値をハッシュで全取得
    ranks.each do |k, v|
      if v<=@user.rank_before_type_cast
        @ranks.store(k, v)
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

  private

  def user_params
    params.require(:user).permit(:name, :email)
  end

end
