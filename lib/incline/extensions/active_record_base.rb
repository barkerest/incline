require 'active_record'

module Incline::Extensions
  module ActiveRecordBase

    def to_s # :nodoc:
      if respond_to?(:name)
        send :name
      else
        "ID = #{id}"
      end
    end

    def inspect # :nodoc:
      "#<#{self.class}:#{self.object_pointer} #{to_s}>"
    end

    ##
    # Tests for equality on ID if available.
    def ==(other)
      if self.class.attribute_names.include?('id')
        if other.is_a?(::Numeric)
          id == other
        elsif other.class == self.class
          id == other.id
        else
          false
        end
      else
        self.inspect == other.inspect
      end
    end

    ##
    # Compares by code, name, or to_s depending on if the code or name attributes are present.
    def <=>(other)
      m = self.class.default_sort_method
      my_val = send(m)

      # other can be a string or a model of the same type as this model.
      other_val =
          if other.is_a?(::String)
            other
          elsif other.class == self.class
            other.send(m)
          else
            nil
          end

      my_val <=> other_val
    end

    ##
    # Additional static methods for the ActiveRecord::Base class.
    module ClassMethods

      ##
      # Gets the default sort method for this model.
      #
      # In order of preference this will be 'code', 'name', or 'to_s'.
      #
      # Specifying a search_attribute before using this method will change this behavior.
      #
      #     class MyModel
      #       attr_accessor :id, :name, :employee_id
      #     end
      #     MyModel.default_sort_method   # 'name'
      #
      #     class MyModel
      #       attr_accessor :id, :name, :employee_id
      #       search_attribute :employee_id
      #     end
      #     MyModel.default_sort_method   # 'employee_id'
      def default_sort_method
        @default_sort_method ||= search_attributes.find{|a| attribute_names.include?(a)} || 'to_s'
      end

      ##
      # Specifies an attribute to search in the get_id, get, and [] methods.
      #
      # The default attributes to search are 'code' and 'name'.  If you specify
      # an additional attribute it will be prefixed to the list.  This affects
      # sorting behavior, but not necessarily the search behavior since if the 'code'
      # or 'name' attributes are also present, they will be searched as well.
      #
      #     class MyModel
      #       attr_accessor :id, :name, :employee_id
      #       search_attribute :employee_id
      #     end
      def search_attribute(attrib)
        unless attrib.blank?
          attrib = attrib.to_s.strip
          search_attributes.insert(0, attrib) unless search_attributes.include?(attrib)
        end
      end

      ##
      # Gets the ID(s) based on the specified value.
      #
      # An integer simply gets returned.  No validation is done.
      # A string representing an integer gets converted and returned.  No validation is done.
      #
      # A symbol is converted to a humanized string.
      #
      # Strings are lowercased and compared against :code or :name if either of those is a valid attribute.
      # You can use the search_attribute method to add another attribute to compare against.
      #
      # Arrays are mapped as above.
      #
      # In all cases, if one result is found that value is returned, if more than one is found then an array is returned,
      # and if no results are found, nil is returned.
      def get_id(value)
        return nil unless attribute_names.include?('id')

        return value.id if value.class == self
        return value if value.is_a?(::Integer)
        return value.map{|v| get_id(v)} if value.is_a?(::Array)
        return value.to_i if value.to_s =~ /\A\d+\z/

        result = search_for(value).order(:id).pluck(:id).to_a

        return nil if result.blank?
        return result.first if result.count == 1

        result
      end

      ##
      # Gets one or more items based on the value.
      #
      # Always returns an array of items or nil if no results were found.
      def get(value)
        return value if value.class == self
        result = search_for(value)
        first_sort = search_attributes.find{|a| attribute_names.include?(a)}
        if first_sort
          result = result.order(first_sort, :id)
        else
          result = result.order(:id)
        end
        result = result.to_a
        return nil if result.blank?
        result
      end

      ##
      # Gets one item based on the value.
      #
      # Always returns the first item found or nil if there were no matches.
      def [](value)
        get(value)&.first
      end

      private

      def search_attributes
        @search_attributes ||= %w(code name)
      end

      def search_for(values)

        # make sure we have an array that we can safely modify.
        values = values.is_a?(::Array) ? values.dup : [ values ]

        # extract potential IDs.
        ids =       values
                        .select{|v| v.is_a?(::Integer) || (v.is_a?(::String) && v =~ /\A\d+\z/)}
                        .map{|v| v.to_i}

        # and then extract string/symbol values for further searching.
        values =    values
                        .select{|v| v.is_a?(::String) || v.is_a?(::Symbol)}
                        .map{|v| v.is_a?(::Symbol) ? [ v.to_s.downcase, v.to_s.humanize.downcase ] : v.to_s.humanize.downcase}
                        .flatten

        # get the attributes to search.
        attribs =   search_attributes
                        .select{|attr| attribute_names.include?(attr)}
                        .map{|a| a.to_s.gsub("'", "''").gsub('"','""') }

        # do a sanity check.
        raise 'No valid values to search for.' if ids.blank? && values.blank?
        raise 'No ID attribute to search.' unless ids.blank? || attribute_names.include?('id')
        raise 'No attributes to search.' unless values.blank? || attribs.any?

        filters = []
        filter_values = []
        tbl = table_name.to_s.gsub("'", "''").gsub('"','""')

        # include the ID filters.
        ids.each do |id|
          filters << "(\"#{tbl}\".\"id\" = ?)"
          filter_values << id
        end

        # include the value filters.
        values.each do |value|
          attribs.each do |attr|
            filters << "(LOWER(\"#{tbl}\".\"#{attr}\") = ?)"
            filter_values << value
          end
        end

        filters = filters.join(' OR ')

        self.where(filters, *filter_values)
      end

    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods
      end
    end
  end
end

ActiveRecord::Base.include Incline::Extensions::ActiveRecordBase