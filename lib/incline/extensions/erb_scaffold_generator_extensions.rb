require 'rails/generators'
require 'rails/generators/erb/scaffold/scaffold_generator'

module Incline
  ##
  # Adds one more view to the standard ERB views.
  module ErbScaffoldGeneratorExtensions
    ##
    # Override the "available_views" method to return one more view.
    def self.included(base)
      base.class_eval do
        # point to our templates.
        source_root File.expand_path('../../../templates/erb/scaffold', __FILE__)

        protected

        undef available_views

        # the _list view can be included as a partial for parent items.
        def available_views
          %w(index new edit show _list _form)
        end

      end
    end

  end
end

Erb::Generators::ScaffoldGenerator.include Incline::ErbScaffoldGeneratorExtensions

