module Incline
  ##
  # Parses the parameters sent by a request from datatables.
  class DataTablesRequest

    ##
    # Draw counter.
    def draw
      @config[:draw]
    end

    ##
    # First record to return.
    def start
      @config[:start]
    end

    ##
    # Number of records to return.
    #
    # Can be any positive value, or -1 to indicate that all records should be returned.
    def length
      @config[:length]
    end

    ##
    # Text or regular expression to search with.
    def search
      @config[:search]
    end

    ##
    # The columns requested.
    def columns
      @config[:columns]
    end

    ##
    # The row ordering.
    def ordering
      @config[:order]
    end

    ##
    # Initializes the data tables request parameters.
    def initialize(params = {}, &block)
      raise ArgumentError, 'A block is required to return the starting ActiveRecord scope.' unless block_given?

      @config                   = {}
      @config[:starting_scope]  = block

      params = params.deep_symbolize_keys

      if params[:draw]
        @config[:draw]   = params[:draw].to_s.to_i
        @config[:start]  = params[:start].to_s.to_i
        @config[:length] = params[:length].to_s.to_i

        tmp = params[:search]
        if tmp && !tmp[:value].blank?
          if tmp[:regex].to_bool
            @config[:search] = tmp[:value].is_a?(::Regexp) ? tmp[:value] : Regexp.new(tmp[:value])
          elsif tmp
            @config[:search] = tmp[:value].to_s
          end
        else
          @config[:search] = nil
        end

        tmp               = params[:columns]
        @config[:columns] = [ ]
        if tmp
          tmp = tmp.each_with_index.to_a.map{|(a,b)| [b.to_s,a]}.to_h.deep_symbolize_keys if tmp.is_a?(Array)
          tmp.each do |id, col|
            col[:id] = id.to_s.to_i
            col[:name] = col[:data] if col[:name].blank?
            col[:searchable] = col[:searchable].to_bool
            col[:orderable] = col[:orderable].to_bool

            if col[:search] && !col[:search][:value].blank?
              if col[:search][:regex].to_bool
                col[:search] = col[:search][:value].is_a?(::Regexp) ? col[:search][:value] : Regexp.new(col[:search][:value])
              else
                col[:search] = col[:search][:value].to_s
              end
            else
              col[:search] = nil
            end

            @config[:columns] << col
          end
        end
        @config[:columns].freeze

        tmp             = params[:order]
        @config[:order] = { }
        if tmp
          tmp = tmp.each_with_index.to_a.map{|(a,b)| [b.to_s,a]}.to_h.deep_symbolize_keys if tmp.is_a?(Array)
          tmp.each do |_, order|
            col_id = order[:column].to_i
            col = columns.find{|c| c[:id] == col_id}
            if col
              @config[:order][col[:name]] = ((order[:dir] || 'asc').downcase).to_sym
            end
          end
        end
        @config[:order].freeze
      else
        @config[:draw] = :not_provided
      end

    end


    ##
    # Where the data tables parameters provided?
    def provided?
      draw != :not_provided
    end

    ##
    # Refreshes the data and returns the request instance.
    def refresh!
      records true
      self
    end

    ##
    # Gets the records returned by this request.
    def records(refresh = false)
      @config[:records] = nil if refresh
      @config[:records] ||= load_records
    end

    ##
    # Gets the total number of records before filtering.
    def records_total
      records
      @config[:records_total]
    end

    ##
    # Gets the total number of records after filtering.
    def records_filtered
      records
      @config[:records_filtered]
    end

    ##
    # The error message, if any?
    def error
      records
      @config[:error]
    end

    ##
    # Is there an error to display?
    def error?
      !error.blank?
    end

    private

    ##
    # Applies the request against an ActiveRecord::Relation object.
    #
    # Returns the results of executing the necessary queries and filters as an array of models.
    def load_records(relation = nil)
      begin
        # reset values.
        # @config[:records] is set to the return of this method, we we won't change that here.
        @config[:records_total] = 0
        @config[:records_filtered] = 0
        @config[:error] = nil

        Incline::Log::debug "Loading records for data tables request #{draw}."

        # Get the default starting scope if necessary.
        relation ||= @config[:starting_scope].call

        # store the unfiltered count.
        @config[:records_total] = relation.count

        # If any of these is true, then filtering must be done locally in our code.
        filter_local = (
            search.is_a?(::Regexp) ||
            columns.select{|c| c[:search].is_a?(::Regexp)}.any? ||
            columns.reject {|c| relation.model.column_names.include?(c[:name].to_s)}.any?
        )

        Incline::Log::debug "Filtering will be done #{filter_local ? 'application' : 'database'}-side."

        unless filter_local
          ###  Database Side Individual Filtering  (AND) ###
          columns.reject{|c| c[:search].blank? || c[:name].blank?}.each do |col|
            relation = relation.where("(UPPER(\"#{col[:name]}\") LIKE ?)", "%#{col[:search].upcase}%")
          end

          ###  Database Side Multiple Filtering  (OR) ###
          unless search.blank?
            srch = "%#{search.upcase}%"
            cols = columns.select{|c| c[:searchable]}.map{|c| c[:name].to_s }.reject{|c| c.blank?}
            if cols.any?
              relation = relation.where(
                  cols.map{|c| "(UPPER(\"#{c}\") LIKE ?)"}.join(' OR '),
                  *(cols.map{ srch })
              )
            end
          end
        end

        ###  Database Side Ordering  ###
        if ordering.blank?
          relation = relation.order(id: :asc)
        else
          relation = relation.order(ordering)
        end

        # Now we have two paths, if we are filtering locally, we need to return everything up to this point and
        # perform our filters before limiting the results.
        # If we filtered at the database, then we can limit the results there as well.
        if filter_local
          # execute the query
          relation = relation.to_a

          ###  Local Individual Filtering   (AND) ###
          columns.reject{|c| c[:search].blank? || c[:name].blank?}.each do |col|
            name = col[:name].to_s
            srch = col[:search]
            srch = Regexp.new(srch) unless srch.is_a?(::Regexp)
            relation = relation.select { |item| item.respond_to?(name) && item.send(name) =~ srch }
          end

          ###  Local Multiple Filtering  ###
          unless search.blank?
            srch = search.is_a?(::Regexp) ? search : Regexp.new(search)
            cols = columns.select{|c| c[:searchable]}.map{|c| c[:name].to_s }.reject{|c| c.blank?}
            relation = relation.select{|item| cols.find{|col| item.respond_to?(col) && item.send(col) =~ srch} }
          end

          # store the filtered count.
          @config[:records_filtered] = relation.count

          # apply limits and return.
          relation                   = relation[start..-1]
          if length > 0
            relation = relation[0...length]
          end
          relation
        else
          # store the filtered count.
          @config[:records_filtered] = relation.count

          # apply limits and return.
          relation                   = relation.offset(start)
          if length > 0
            relation = relation.limit(length)
          end
          relation.to_a
        end
      rescue =>err
        @config[:error] = err.message
        Incline::Log::error err
        [ ]
      end
    end

  end
end