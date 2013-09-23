Fbwatch::Application.routes.draw do
  get "sync/all", to: 'sync#syncall', as: 'sync_all'
  
  get "sync(/:name)", to: 'sync#index', :constraints => { :name => /[^\/]+/ }, as: 'sync'
  
  get "sync/disable/:name", to: 'sync#disable', :constraints => { :name => /[^\/]+/ }, as: 'sync_disable'
  get "sync/enable/:name", to: 'sync#enable', :constraints => { :name => /[^\/]+/ }, as: 'sync_enable'
  get "sync/clear/:name", to: 'sync#clear', :constraints => { :name => /[^\/]+/ }, as: 'sync_clear'

  get "apitest", to: 'apitest#index'

  resources :resources
  
  get 'resource/:username(/:p)', to: 'resources#details', :constraints => { :username => /[^\/]+/ }, as: 'resource_details'
  
  get "home/index"
  
  get "login", to: 'home#login'

  root :to => 'home#index'

  get '(:p)' => 'home#index', as: 'root_paging'
  
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  get 'apitest', to: 'apitest#index'

  get 'metrics/:username', to: 'metrics#run', :constraints => { :username => /[^\/]+/ }, as: 'run_metrics'

  get 'group/:id', to: 'resource_groups#details', as: 'resource_group_details'
  resources :resource_groups, only: [:create, :destroy, :update]

  post 'resource/:id/groups', to: 'resources#add_to_group', as: 'add_resource_to_group'
  post 'group/mass', to: 'resource_groups#mass_assign', as: 'resource_group_mass_assign'
end
