require 'jbuilder/jbuilder_template'

module Incline
  ##
  # Adds the +api_errors+ method to be used in jbuilder views to easily list
  # errors for a model in a form that is compatible with the DataTables API.
  module JbuilderTemplateExtensions

    ##
    # List out the errors for the model.
    #
    # model_name::   The singular name for the model (e.g. - "user_account")
    # model_errors:: The errors collection from the model.
    #
    #   json.api_errors! "user_account", user.errors
    #
    def api_errors!(model_name, model_errors)
      base_error = model_errors[:base]
      field_errors = model_errors.reject{ |k,_| k == :base }
      unless base_error.blank?
        set! 'error', "#{model_name.humanize} #{base_error.map{|e| h(e.to_s)}.join("<br>\n#{model_name.humanize} ")}"
      end
      unless field_errors.blank?
        set! 'fieldErrors' do
          array! field_errors do |k,v|
            set! 'name',   "#{model_name}.#{k}"
            set! 'status', v.is_a?(Array) ?
                "#{k.to_s.humanize} #{v.map{|e| h(e.to_s)}.join("<br>\n#{k.to_s.humanize} ")}" :
                "#{k.to_s.humanize} #{h v.to_s}"
          end
        end
      end
    end

  end
end

JbuilderTemplate.include Incline::JbuilderTemplateExtensions

