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
    # If we are searching for a specific ID, this is the ID to locate.
    #
    #
    def locate_id
      @config[:locate_id]
    end

    ##
    # Initializes the data tables request parameters.
    def initialize(params = {}, &block)
      raise ArgumentError, 'A block is required to return the starting ActiveRecord scope.' unless block_given?

      @config                   = {}
      @config[:starting_scope]  = block

      params = params.deep_symbolize_keys

      force_regex = params[:force_regex]

      if params[:draw]
        @config[:draw]   = params[:draw].to_s.to_i
        @config[:start]  = params[:start].to_s.to_i
        @config[:length] = params[:length].to_s.to_i
        @config[:locate_id] = params[:locate_id]


        tmp = params[:search]
        if tmp && !tmp[:value].blank?
          if tmp[:regex].to_bool || force_regex
            @config[:search] =
                if tmp[:value].is_a?(::Regexp)
                  tmp[:value]
                else
                  begin
                    Regexp.new(tmp[:value].to_s, Regexp::IGNORECASE)
                  rescue RegexpError
                    tmp[:value].to_s
                  end
                end
          elsif tmp
            @config[:search] = tmp[:value].to_s
          end
        else
          @config[:search] = nil
        end

        tmp               = params[:columns]
        @config[:columns] = [ ]
        if tmp
          tmp = tmp.each_with_index.to_a.map{|(a,b)| [b.to_s,a]}.to_h.deep_symbolize_keys if tmp.is_a?(::Array)
          tmp.each do |id, col|
            col[:id] = id.to_s.to_i
            col[:name] = col[:data] if col[:name].blank?
            col[:searchable] = col[:searchable].to_bool
            col[:orderable] = col[:orderable].to_bool

            if col[:search] && !col[:search][:value].blank?
              if col[:search][:regex].to_bool || force_regex
                col[:search] =
                    if col[:search][:value].is_a?(::Regexp)
                      col[:search][:value]
                    else
                      begin
                        Regexp.new(col[:search][:value].to_s, Regexp::IGNORECASE)
                      rescue RegexpError
                        col[:search][:value].to_s
                      end
                    end
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
          tmp = tmp.each_with_index.to_a.map{|(a,b)| [b.to_s,a]}.to_h.deep_symbolize_keys if tmp.is_a?(::Array)
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
    # If #locate_id is non-zero, this is the record number for the specified ID using our filtering parameters.
    #
    # This will be an absolute zero-based record number for the ID.  It can be used to figure out the page that the
    # record would appear on.
    def record_location(refresh = false)
      @config[:record_location] = nil if refresh
      @config[:record_location] ||= find_record
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
    # Find the record represented by #locate_id.
    def find_record(relation = nil)
      if locate_id.nil? || (locate_id.is_a?(::Numeric) && locate_id == 0) || (locate_id.to_s == '')
        return -1
      end

      dataset = load_records(relation, false)
      return -1 if dataset.blank?
      
      first_item = dataset.first
      klass = first_item.class
      
      id_field = klass.respond_to?('primary_key')       ? klass.primary_key   : nil
      id_field ||= first_item.respond_to?('id')         ? 'id'                : nil

      return -1 unless id_field
      if locate_id.is_a?(::Numeric)
        dataset.index{|item| item.send(id_field) == locate_id} || -1
      else
        loc_id = locate_id.to_s.downcase
        dataset.index{|item| item.send(id_field).to_s.downcase == loc_id} || -1
      end
      
    end

    ##
    # Applies the request against an ActiveRecord::Relation object.
    #
    # Returns the results of executing the necessary queries and filters as an array of models.
    def load_records(relation = nil, paging = true)
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

        # If we have search parameters and any of the search parameters is a regular expression or 
        # one or more columns being searched is not a database column, then filtering must be done
        # locally.
        filter_local =
            !(search.blank? && columns.reject{|c| c[:search].blank? }.blank?) &&
                (
                    # main search is a regex.
                    search.is_a?(::Regexp) ||
                    # one or more column searches is a regex.
                    columns.select{|c| c[:search].is_a?(::Regexp)}.any? ||
                    # one or more searchable columns is not in the database model
                    columns.reject {|c| !c[:searchable] || relation.model.column_names.include?(c[:name].to_s) }.any?
                )

        order_local = ordering.blank? || ordering.reject{|k,_| relation.model.column_names.include?(k.to_s)}.any?

        Incline::Log::debug "Filtering will be done #{(filter_local || order_local) ? 'application' : 'database'}-side."
        Incline::Log::debug "Ordering will be done #{order_local ? 'application' : 'database'}-side."

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
        unless order_local
          relation = relation.order(ordering)
        end

        # Now we have two paths, if we are filtering/ordering locally, we need to return everything up to this point and
        # perform our filters before limiting the results.
        # If we filtered and ordered at the database, then we can limit the results there as well.
        if filter_local || order_local
          # execute the query
          relation = relation.to_a

          ###  Application Side Ordering  ###
          if order_local
            ordering_list = ordering.to_a
            relation.sort{|a,b| local_sort(a, b, ordering_list) }
          end

          ###  Local Individual Filtering   (AND) ###
          columns.reject{|c| c[:search].blank? || c[:name].blank?}.each do |col|
            name = col[:name].to_s
            srch = col[:search]
            relation =
                if srch.is_a?(::Regexp)
                  relation.select { |item| item.respond_to?(name) && item.send(name) =~ srch }
                else
                  srch = srch.to_s.upcase
                  relation.select { |item| item.respond_to?(name) && item.send(name).to_s.upcase.include?(srch) }
                end
          end

          ###  Local Multiple Filtering  ###
          unless search.blank?
            cols = columns.select{|c| c[:searchable]}.map{|c| c[:name].to_s }.reject{|c| c.blank?}
            relation =
                if search.is_a?(::Regexp)
                  relation.select{|item| cols.find{|col| item.respond_to?(col) && item.send(col) =~ search} }
                else
                  srch = search.to_s.upcase
                  relation.select{|item| cols.find{|col| item.respond_to?(col) && item.send(col).to_s.upcase.include?(srch) }}
                end
          end

          # store the filtered count.
          @config[:records_filtered] = relation.count

          if paging
            # apply limits and return.
            relation                   = relation[start..-1]
            if length > 0
              relation = relation[0...length]
            end
          end
          relation
        else
          # store the filtered count.
          @config[:records_filtered] = relation.count

          if paging
            # apply limits and return.
            relation                   = relation.offset(start)
            if length > 0
              relation = relation.limit(length)
            end
          end
          relation.to_a
        end
      rescue =>err
        @config[:error] = err.message
        Incline::Log::error err
        [ ]
      end
    end

    private

    def local_sort(a, b, attribs, index = 0)
      if index >= attribs.count
        0
      else
        attr, dir = attribs[index]
        val_a = a.send(attr)
        val_b = b.send(attr)
        if val_a == val_b
          local_sort a, b, attribs, index + 1
        else
          if dir.to_s.downcase == 'desc'
            val_b <=> val_a
          else
            val_a <=> val_b
          end
        end
      end
    end

  end
end