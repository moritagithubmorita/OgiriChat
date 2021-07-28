class Admin::UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end
  
  def edit
    @user = User.find(params[:id])
  end
  
  def update
    @user = User.find(params[:id])
    if @user.update(user_params)
  end
  
  def index
    @users = User.all
  end
  
  private
  
  def user_params
    params.require(:user).permit(:name, :email, :)
  end
end
