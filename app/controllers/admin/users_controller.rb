class Admin::UsersController < ApplicationController
  before_action :signed_in_check
  
  def signed_in_check
    if !admin_signed_in?
      redirect_to new_admin_session_path
    end
  end
  
  def show
    @user = User.find(params[:id])
  end

  def edit
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
      redirect_to admin_user_path(params[:id])
    else
      render :edit
    end
  end

  def index
    @users = User.all
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :rank, :is_active)
  end
end
