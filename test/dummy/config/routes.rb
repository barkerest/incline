Rails.application.routes.draw do

  mount Incline::Engine => "/incline"

  # need to ensure that custom root paths work.
  root 'dummy#hello'
  # root 'incline/welcome#home'
end
