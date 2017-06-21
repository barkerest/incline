require 'rails/generators'
require 'generators/rails/jbuilder_generator'

module Incline::Extensions
  ##
  # Adds _details view to jbuilder.
  module JbuilderGenerator

    ##
    # Overrides the copy_view_files method to include the _details view.
    def self.included(base)
      base.class_eval do

        source_root File.expand_path('../../../templates/jbuilder/scaffold', __FILE__)

        undef copy_view_files

        def copy_view_files
          available_views.each do |view|
            filename = filename_with_extensions(view)
            template filename, File.join('app/views', controller_file_path, filename)
          end
        end

        protected

        def available_views
          %w(index show _details)
        end

      end
    end

  end
end

Rails::Generators::JbuilderGenerator.include Incline::Extensions::JbuilderGenerator

