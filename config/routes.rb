Fbwatch::Application.routes.draw do
  get "sync/:name", to: 'sync#index', as: 'sync'

  get "sync/all", to: 'sync#syncall'

  get "apitest/index"

  resources :resources
  
  get 'resource/:username', to: 'resources#details'
  
  get "home/index"
  
  get "login", to: 'home#login'

  root :to => 'home#index'
  
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  get 'apitest', to: 'apitest#index'
end
