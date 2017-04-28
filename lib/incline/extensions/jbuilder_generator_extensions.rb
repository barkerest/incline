require 'rails/generators'
require 'generators/rails/jbuilder_generator'

module Incline
  ##
  # Adds _details view to jbuilder.
  module JbuilderGeneratorExtensions

    ##
    # Overrides the copy_view_files method to include the _details view.
    def self.included(base)
      base.class_eval do

        source_root File.expand_path('../../../templates/jbuilder/scaffold', __FILE__)

        undef copy_view_files

        def copy_view_files
          %w(index show _details).each do |view|
            filename = filename_with_extensions(view)
            template filename + '_erb', File.join('app/views', controller_file_path, filename)
          end
        end

      end
    end

  end
end

Rails::Generators::JbuilderGenerator.include Incline::JbuilderGeneratorExtensions

