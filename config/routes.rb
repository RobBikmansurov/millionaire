Rails.application.routes.draw do
  devise_for :users
  resources :users, only: %i[index show]
  resources :games, only: %i[create show] do
    put 'help', on: :member # помощь зала
    put 'answer', on: :member # ответ на текущий вопрос
    put 'take_money', on: :member # игрок берет деньги
  end
  # Ресурс в единственном числе - ВопросЫ
  # для загрузки админом сразу пачки вопросОВ
  resource :questions, only: %i[new create]
  root 'users#index'
  mount RailsAdmin::Engine => '/admin', as: 'rails_admin'
end
