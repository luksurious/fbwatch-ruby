Fbwatch::Application.routes.draw do
  # general actiosn
  get "home/index"
  root :to => 'home#index'
  get '(:p)' => 'home#index', as: 'root_paging'
  
  get "apitest", to: 'apitest#index'

  # sync actions
  get "sync/all", to: 'sync#syncall', as: 'sync_all'
  get "sync(/:name)", to: 'sync#index', :constraints => { :name => /[^\/]+/ }, as: 'sync'
  get "sync/clear/:name", to: 'sync#clear', :constraints => { :name => /[^\/]+/ }, as: 'sync_clear'
  
  # resource actions
  resources :resources
  get "resource/:username/disable", to: 'resources#disable', :constraints => { :username => /[^\/]+/ }, as: 'sync_disable'
  get "resource/:username/enable", to: 'resources#enable', :constraints => { :username => /[^\/]+/ }, as: 'sync_enable'
  get 'resource/:username(/:p)', to: 'resources#details', :constraints => { :username => /[^\/]+/, :p => /[0-9]+/ }, as: 'resource_details'
  post 'resource/:id/groups', to: 'resources#add_to_group', as: 'add_resource_to_group'

  # metrics
  get 'resource/:username/metrics', to: 'metrics#run', :constraints => { :username => /[^\/]+/ }, as: 'run_metrics'

  # login actions
  get "login", to: 'home#login'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  # group actions
  resources :resource_groups, only: [:create, :destroy, :update]
  get 'group/:id', to: 'resource_groups#details', as: 'resource_group_details'
  post 'group/mass', to: 'resource_groups#mass_assign', as: 'resource_group_mass_assign'
  patch 'group/:id/activate', to: 'resource_groups#activate', as: 'activate_group'
  patch 'group/:id/deactivate', to: 'resource_groups#deactivate', as: 'deactivate_group'
end
