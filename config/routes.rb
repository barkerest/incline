Incline::Engine.routes.draw do

  get 'signup' => 'users#new'

  resources :users, except: [ :new ]

end
