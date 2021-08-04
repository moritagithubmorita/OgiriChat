# frozen_string_literal: true

class Public::SessionsController < Devise::SessionsController
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

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  # def create
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
