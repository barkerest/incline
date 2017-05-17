Incline::Engine.routes.draw do

  # user management
  get     'signup'    => 'users#new'
  post    'signup'    => 'users#create'
  resources :users, except: [ :new, :create ] do
    member do
      get   'disable',      action: :disable_confirm
      patch 'disable'
      put   'disable'
      patch 'enable'
      put   'enable'
    end
    collection do
      get   'api'
      post  'api'
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

  # welcome route.
  get '/' => 'welcome#home', as: :welcome

end
