require 'rails/generators'
require 'rails/generators/rails/resource_route/resource_route_generator'

module Incline::Extensions
  module ResourceRouteGenerator

    ##
    # Overrides the add_resource_route method.
    def self.included(base)
      base.class_eval do
        undef add_resource_route

        ##
        # Adds a resource route with additional :api and :locate actions.
        def add_resource_route
          return if options[:actions].present?

          # iterates over all namespaces and opens up blocks
          regular_class_path.each_with_index do |namespace, index|
            write("namespace :#{namespace} do", index + 1)
          end

          # inserts the primary resource with api routes as well.
          pad = '  ' * (route_length + 1)
          write <<-EOR, 0
#{pad}resources :#{file_name.pluralize} do
#{pad}  member do
#{pad}    post :locate
#{pad}  end
#{pad}  collection do
#{pad}    match :api, via: [ :get, :post ]
#{pad}  end
#{pad}end
          EOR

          # ends blocks
          regular_class_path.each_index do |index|
            write("end", route_length - index)
          end

          # route prepends two spaces onto the front of the string that is passed, this corrects that.
          # Also it adds a \n to the end of each line, as route already adds that
          # we need to correct that too.
          route route_string[2..-2]
        end

      end
    end

  end
end

Rails::Generators::ResourceRouteGenerator.include Incline::Extensions::ResourceRouteGenerator