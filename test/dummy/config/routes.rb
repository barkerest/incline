Rails.application.routes.draw do

  mount Incline::Engine => "/incline"

  root 'incline/welcome#home'
end
