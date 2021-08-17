# frozen_string_literal: true

class Public::SessionsController < Devise::SessionsController
  # 管理者とユーザの同時ログイン状態を禁止する
  before_action :admin_signed_in_check, only: [:create]
  #退会顧客がログインできないようにする
  before_action :loginable_check, only: [:create]

  #退会済み顧客のログインを阻止する処理
  def loginable_check
    #入力メアドと合致するCustomerを検索
    user = User.find_by(email: params[:user][:email])
    #退会済み顧客だった場合
    if (user && !user.is_active)
      redirect_to new_user_registration_path
    end
  end

  # ユーザと管理者の同時ログインを禁止する
  def admin_signed_in_check
    # 管理者としてログインしていた場合ログアウト
    if admin_signed_in?
      # reset_session
      sign_out current_admin
    end
  end

  def after_sign_in_path_for(resource)
    root_path
  end

  def after_sign_out_path_for(resource)
    root_path
  end

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
  #   binding.pry
  #   super
  # end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
