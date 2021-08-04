Rails.application.routes.draw do
  scope module: :public do
    resources :notices, only: :index
    resources :inquiries, only: [:new, :create]
    resource :users, only: [:show, :edit, :update]
  end

  devise_for :users, :controllers =>{
    :sessions => 'public/sessions',
    :registrations => 'public/registrations'
  }

  root to: "public/homes#top"
  get "homes/stand_by" => 'public/homes#stand_by', as: 'stand_by'

  get "question_rooms/match_make" => 'public/question_rooms#match_make', as: 'match_make'
  get "question_rooms/battle" => 'public/question_rooms#battle', as: 'battle'
  get "question_rooms/finish" => 'public/question_rooms#finish', as: 'finish'
  get "question_rooms/result" => 'public/question_rooms#result', as: 'result'

  get "users/confirm" => 'public/users#confirm', as: 'confirm'
  patch "users/withdraw" => 'public/users#withdraw', as: 'withdraw'

  post "follows/follow" => 'public/follows#follow', as: 'follow'
  get "follows/toggle" => 'public/follows#toggle', as: 'follow_toggle'

  devise_for :admin, :controllers =>{
    :sessions => 'admin/sessions'
  }
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  namespace :admin do
    get '/homes/top' => 'homes#top'
    get '/homes/search' => 'homes#search'
    resources :users, only: [:edit, :update, :index, :show]
    resources :question_rooms
    resources :inquiries, only: [:update, :index, :show, :edit]
  end

  mount ActionCable.server => '/cable'

end
