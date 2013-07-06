Fbwatch::Application.routes.draw do
  get "sync/all", to: 'sync#syncall', as: 'sync_all'
  
  get "sync/:name", to: 'sync#index', :constraints => { :name => /[^\/]+/ }, as: 'sync'
  
  get "sync/disable/:name", to: 'sync#disable', :constraints => { :name => /[^\/]+/ }, as: 'sync_disable'
  get "sync/enable/:name", to: 'sync#enable', :constraints => { :name => /[^\/]+/ }, as: 'sync_enable'
  get "sync/clear/:name", to: 'sync#clear', :constraints => { :name => /[^\/]+/ }, as: 'sync_clear'

  get "apitest/index"

  resources :resources
  
  get 'resource/:username', to: 'resources#details', :constraints => { :username => /[^\/]+/ }, as: 'resource_details'
  
  get "home/index"
  
  get "login", to: 'home#login'

  root :to => 'home#index'
  
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  get 'apitest', to: 'apitest#index'
end
