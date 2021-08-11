class Admin::InquiriesController < ApplicationController
  before_action :signed_in_check
  
  def signed_in_check
    if !admin_signed_in?
      redirect_to new_admin_session_path
    end
  end
  
  def index
    @inquiries = Inquiry.all.order("created_at DESC")
  end

  # お問い合わせ詳細画面
  def show
  # 処理内容
  # 表示されたお問い合わせを既読(is_readed: true)にする
    
    @inquiry = Inquiry.find(params[:id])
    @inquiry.update(is_readed: true)
  end

  def edit
    @inquiry = Inquiry.find(params[:id])
  end

  def update
    @inquiry = Inquiry.find(params[:id])
    if @inquiry.update(inquiry_params)
      redirect_to admin_inquiry_path(@inquiry.id)
    else
      render :edit
    end
  end

  private

  def inquiry_params
    params.require(:inquiry).permit(:is_solved)
  end
end
