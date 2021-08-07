class Admin::HomesController < ApplicationController
  def top
    @question_rooms = QuestionRoom.all.order("created_at DESC")
  end
  
  # 検索結果画面
  def search
    # 検索対象は「回答者名」「回答」「お題」
    # 検索は部分一致で行う
    
    key = params[:search]
    
    # 回答者名
    @users = User.where("name LIKE ?", "%#{key}%")
    
    # 回答
    @answers = Answer.where("body LIKE ?", "%#{key}%")
    
    # お題
    @question_rooms = QuestionRoom.where("body LIKE ?", "%#{key}%")
  end
end
