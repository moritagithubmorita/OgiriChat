class Public::NoticesController < ApplicationController
  def index
    @notices = current_user.notices.order("created_at DESC")
  end
end
