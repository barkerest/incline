require 'rails/generators'
require 'rails/generators/rails/resource_route/resource_route_generator'

module Incline::Extensions
  module ResourceRouteGenerator

    ##
    # Adds a resource route with additional :api and :locate actions.
    def add_resource_route
      return if options[:actions].present?

      # iterates over all namespaces and opens up blocks
      regular_class_path.each_with_index do |namespace, index|
        write("namespace :#{namespace} do", index + 1)
      end

      # inserts the primary resource with api routes as well.
      write "resources :#{file_name.pluralize} do", route_length + 1
      write "member do", route_length + 2
      write "post :locate", route_length + 3
      write "end", route_length + 2
      write "collection do", route_length + 2
      write "match :api, via: [ :get, :post ]", route_length + 3
      write "end", route_length + 2
      write "end", route_length + 1

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

Rails::Generators::ResourceRouteGenerator.include Incline::Extensions::ResourceRouteGenerator