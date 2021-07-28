class Admin::QuestionRoomsController < ApplicationController

  def new
    @question_room = QuestionRoom.new()
  end

  def create
    @question_room = QuestionRoom.new(question_room_params)
    @question_room.added_by = current_admin.id
    # binding.pry
    if @question_room.save
      redirect_to admin_question_room_path(@question_room.id)
    else
      render :new
    end
  end

  def show
    @question_room = QuestionRoom.find(params[:id])
  end

  private

  def question_room_params
    params.require(:question_room).permit(:body, :is_active)
  end

end

