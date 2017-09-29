module Incline::Extensions
  module CurrentRequest
    def self.included(base)
      base.class_eval do
        private
        
        def store_current_request
          ::Thread.current.thread_variable_set :incline_current_request, request
        end
        
        before_action :store_current_request
      end
    end
  end
end

module Incline
  def self.current_request
    th = ::Thread.current
    th.thread_variable?(:incline_current_request) ? th.thread_variable_get(:incline_current_request) : nil
  end
end

ActionController::Base.include ::Incline::Extensions::CurrentRequest

