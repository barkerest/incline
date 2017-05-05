module Incline

  ##
  # An exception used to indicate when a user is not logged in.
  NotLoggedIn = Class.new(StandardError)

  ##
  # An exception used to indicate when a user is not authorized.
  NotAuthorized = Class.new(StandardError)

  ##
  # An exception used to indicate an invalid API call.
  InvalidApiCall = Class.new(StandardError)

end