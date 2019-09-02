Rails.application.routes.draw do
  devise_for :admins
  resources :categories, only: [:show]
  resources :products, only: [:index, :show]
  get 'welcome/index'
  root 'welcome#index'

  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
