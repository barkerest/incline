Incline::Engine.routes.draw do

  root 'welcome#home'
  get 'signup' => 'users#new'

end
