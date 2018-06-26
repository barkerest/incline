require 'action_dispatch/http/url'

module ActionDispatch::Http::URL
  
  ##
  # Enables automatic parameter propagation.
  #
  # This will only propagate within the current thread.  Child threads will not propagate.
  # This will not affect other requests in the current session.
  #
  #   ActionDispatch::Http::URL.propagated_params << :some_param
  def self.propagated_params
    @propagated_params ||= []
  end

  class << self
    alias :incline_original_path_for :path_for
  end

  def self.path_for(options)
    if (request = Incline::current_request)
      propagated_params.each do |k|
        if request.params.key? k
          options[:params] ||= {}
          options[:params][k] = request.params[k]
        end
      end
    end

    incline_original_path_for(options)
  end

end

