class Public::InquiriesController < ApplicationController
  before_action :signed_in_check, only: [:new]

  def new
    @inquiry = Inquiry.new()
  end

  def create
    @inquiry = Inquiry.new(inquiry_params)
    if @inquiry.save
      redirect_to root_path
    else
      render :new
    end
  end

  private

  # ユーザ未ログインならユーザログイン画面に遷移
  def signed_in_check
    if !user_signed_in?
      redirect_to new_user_session_path
    end
  end

  def inquiry_params
    params.require(:inquiry).permit(:title, :body, :user_id)
  end
end
