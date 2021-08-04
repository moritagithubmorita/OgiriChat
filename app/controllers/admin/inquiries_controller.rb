class Admin::InquiriesController < ApplicationController
  def index
    @inquiries = Inquiry.all.order("created_at DESC")
  end

  def show
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
