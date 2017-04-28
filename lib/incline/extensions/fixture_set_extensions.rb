require 'active_record/fixtures'

module Incline
  ##
  # Extends the fixture sets so that tables can be loaded/purged in a specific order.
  module FixtureSetExtensions

    ##
    # Provides static methods for the ActiveRecord::FixtureSet class.
    module ClassMethods # :nodoc:

      ##
      # Determines the fixtures that will be loaded first.
      #
      # Arguments can either be just table names or a hash of table names with indexes.
      # If just table names, then the tables are inserted at the end of the list.
      # If a hash, then the value is the index you want the table to appear in the load list.
      #
      # Usage:
      #   ActiveRecord::FixtureSet.load_first :table_1, :table_2
      #   ActiveRecord::FixtureSet.load_first :table_1 => 0, :table_2 => 1
      def load_first(*args)
        priority_list = %w(incline/users incline/permissions)

        @load_first ||= priority_list

        unless args.blank?
          args.each do |arg|
            if arg.is_a?(Hash)
              arg.each do |fix,order|
                fix = fix.to_s
                order += priority_list.length
                if order >= @load_first.length
                  @load_first << fix unless @load_first.include?(fix)
                else
                  @load_first.insert(order, fix) unless @load_first.include?(fix)
                end
              end
            else
              fix = arg.to_s
              @load_first << fix unless @load_first.include?(fix)
            end
          end
        end

        @load_first
      end

      ##
      # Determines the fixtures that will purged first.
      #
      # Arguments can either be just table names or a hash of table names with indexes.
      # If just table names then the tables are inserted at the beginning of the list.
      # If a hash, then the value is the index you want the table to appear in the purge list.
      #
      # Usage:
      #   ActiveRecord::FixtureSet.purge_first :table_1, :table_2
      #   ActiveRecord::FixtureSet.purge_first :table_1 => 0, :table_2 => 1
      def purge_first(*args)
        priority_list = %w(incline/permissions_users)

        @purge_first ||= priority_list

        unless args.blank?
          args.reverse.each do |arg|
            if arg.is_a?(Hash)
              arg.each do |fix,order|
                fix = fix.to_s
                if order <= 0
                  @purge_first.insert(0, fix) unless @purge_first.include?(fix)
                elsif order >= @purge_first.length - priority_list.length
                  @purge_first.insert(@purge_first.length - priority_list.length, fix) unless @purge_first.include?(fix)
                else
                  @purge_first.insert(order, fix) unless @purge_first.include?(fix)
                end
              end
            else
              fix = arg.to_s
              @purge_first.insert(0, fix) unless @purge_first.include?(fix)
            end
          end
        end

        @purge_first
      end

      ##
      # Purges and then recreates the fixtures using the prioritized order.
      def self.create_fixtures(fixtures_dir, fixture_set_names, *args)
        conn = ActiveRecord::Base.connection

        # delete all fixtures that have been added to purge_first
        purge_first.each do |fix|
          klass = const_get(fix.classify) rescue nil
          if klass&.respond_to?(:delete_all)
            # This is a model.
            klass.delete_all
          else
            # This is probably a join table.
            tbl = fix.gsub('/', '_')
            if conn.object_exists?(tbl)
              conn.execute "DELETE FROM \"#{tbl}\""
            else
              Incline::Log::warn "Cannot purge fixture \"#{fix}\" since it doesn't reference a model or a table in the default connection."
            end
          end
        end

        reset_cache

        # if we are adding any of the prioritized fixtures, make them go first, followed by any other fixtures.
        fixture_set_names = load_first & fixture_set_names | fixture_set_names

        incline_original_create_fixtures fixtures_dir, fixture_set_names, *args
      end

    end

    ##
    # Adds the prioritized order methods and overrides create_fixtures to make use of them.
    def self.included(base) #:nodoc:
      base.class_eval do
        class << self
          alias :incline_original_create_fixtures :create_fixtures
        end
      end

      base.extend ClassMethods
    end

  end
end

ActiveRecord::FixtureSet.include Incline::FixtureSetExtensions