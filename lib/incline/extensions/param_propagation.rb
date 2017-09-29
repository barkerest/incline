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
  
  def self.path_for(options)
    
    if (request = Incline::current_request)
      propagated_params.each do |k|
        if request.params.key? k
          options[:params] ||= {}
          options[:params][k] = request.params[k]
        end
      end
    end
    
    path  = options[:script_name].to_s.chomp("/")
    path << options[:path] if options.key?(:path)

    add_trailing_slash(path) if options[:trailing_slash]
    add_params(path, options[:params]) if options.key?(:params)
    add_anchor(path, options[:anchor]) if options.key?(:anchor)

    path
  end

end

