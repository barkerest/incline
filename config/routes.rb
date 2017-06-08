Incline::Engine.routes.draw do

  # user management
  get     'signup'    => 'users#new'
  post    'signup'    => 'users#create'
  resources :users, except: [ :new, :create ] do
    member do
      get   'disable',      action: :disable_confirm
      match 'disable',      via: [ :put, :patch ]
      match 'enable',       via: [ :put, :patch ]
      match 'promote',      via: [ :put, :patch ]
      match 'demote',       via: [ :put, :patch ]
    end
    collection do
      match 'api', via: [ :get, :post ]
    end
  end

  # login/logout
  get     'login'     => 'sessions#new'
  post    'login'     => 'sessions#create'
  delete  'logout'    => 'sessions#destroy'

  # account activation route
  get     'activate/:id'  => 'account_activations#edit', as: :edit_account_activation

  # password reset routes
  resources :password_resets, only: [ :new, :create, :edit, :update ]

  # contact routes
  get   'contact' => 'contact#new'
  post  'contact' => 'contact#create'

  # access groups
  resources :access_groups



end
