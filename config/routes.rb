Fbwatch::Application.routes.draw do
  # general actions
  root :to => 'home#index_groups'
  
  get "apitest", to: 'apitest#index'

  get "tasks", to: 'home#tasks', as: 'tasks'
  patch 'tasks/resume/:id', to: 'home#resume_task', as: 'resume_task'

  # sync actions
  get "sync/all", to: 'sync#all', as: 'sync_all'
  get "sync(/:name)", to: 'sync#resource', :constraints => { :name => /[^\/]+/ }, as: 'sync'
  get "sync/clear/:name", to: 'sync#clear', :constraints => { :name => /[^\/]+/ }, as: 'sync_clear'
  
  # resource actions
  get 'resources(/:p)' => 'resources#index', as: 'resources_index', constraints: { p: /[0-9]+/ }

  resources :resources
  get "resource/:username/disable", to: 'resources#disable', :constraints => { :username => /[^\/]+/ }, as: 'sync_disable'
  get "resource/:username/enable", to: 'resources#enable', :constraints => { :username => /[^\/]+/ }, as: 'sync_enable'
  get 'resource/:username(/:p)', to: 'resources#details', :constraints => { :username => /[^\/]+/, :p => /[0-9]+/ }, as: 'resource_details'
  post 'resource/:id/groups', to: 'resources#add_to_group', as: 'add_resource_to_group'

  # metrics
  patch 'resource/:username/metrics', to: 'metrics#resource', :constraints => { :username => /[^\/]+/ }, as: 'run_metrics'
  patch 'group/:id/metrics', to: 'metrics#group', as: 'group_metrics'

  # login actions
  get "login", to: 'sessions#login'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  # group actions
  resources :resource_groups, only: [:create, :destroy, :update]
  get 'group/:id', to: 'resource_groups#details', as: 'resource_group_details'
  post 'group/mass', to: 'resource_groups#mass_assign', as: 'resource_group_mass_assign'
  patch 'group/:id/activate', to: 'resource_groups#activate', as: 'activate_group'
  patch 'group/:id/deactivate', to: 'resource_groups#deactivate', as: 'deactivate_group'
  patch 'group/:id/sync', to: 'sync#group', as: 'sync_group'
  delete 'group/:id/resource/:resource_id', to: 'resource_groups#remove_resource', as: 'remove_resource_from_group'
end
