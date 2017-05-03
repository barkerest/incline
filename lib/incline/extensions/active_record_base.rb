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
    # Additional static methods for the ActiveRecord::Base class.
    module ClassMethods

      ##
      # Gets the ID(s) based on the specified value.
      #
      # An integer simply gets returned.  No validation is done.
      # A string representing an integer gets converted and returned.  No validation is done.
      #
      # A symbol is converted to a humanized string.
      #
      # Strings are lowercased and compared against :code or :name if either of those is a valid attribute.
      #
      # Arrays are mapped as above.
      #
      # In all cases, if one result is found that value is returned, if more than one is found then an array is returned,
      # and if no results are found, nil is returned.
      def get_id(value)
        return value.id if value.class == self
        return value if value.is_a?(Integer)
        return value.map{|v| get_id(v)} if value.is_a?(Array)
        return value.to_i if value.to_s =~ /^\d+$/

        test = []
        test << :code if attribute_names.include?(:code) || attribute_names.include?('code')
        test << :name if attribute_names.include?(:name) || attribute_names.include?('name')

        return nil if test.blank?

        value = value.to_s.humanize if value.is_a?(Symbol)
        value = value.to_s.downcase

        filt = test.map{|v| "(LOWER(\"#{v}\") = ?)"}.join(' OR ')
        result = self.where(filt, *(test.map{value})).order(:id).pluck(:id).to_a

        return nil if result.blank?
        return result.first if result.count == 1

        result
      end

      ##
      # Gets one or more items based on the value.
      #
      # Always returns an array of items.
      def get(value)
        return value if value.class == self
        result = where(id: get_id(value))
        if attribute_names.include?(:code) || attribute_names.include?('code')
          result = result.order(:code, :id)
        elsif attribute_names.include?(:name) || attribute_names.include?('name')
          result = result.order(:name, :id)
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
      # Always returns the first item found.
      def [](value)
        get(value)&.first
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