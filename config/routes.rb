Rails.application.routes.draw do
  get 'heads_up/:room_id', to: "heads_up#show"

  root to: 'home#show'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  mount ActionCable.server => '/cable'
end
