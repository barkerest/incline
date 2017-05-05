module Incline
  ##
  # Parses the parameters sent by a request from datatables.
  class DataTablesRequest

    ##
    # Draw counter.
    def draw
      @data[:draw]
    end

    ##
    # First record to return.
    def start
      @data[:start]
    end

    ##
    # Number of records to return.
    #
    # Can be any positive value, or -1 to indicate that all records should be returned.
    def length
      @data[:length]
    end

    ##
    # Text or regular expression to search with.
    def search
      @data[:search]
    end

    ##
    # The columns requested.
    def columns
      @data[:columns]
    end

    ##
    # The row ordering.
    def ordering
      @data[:order]
    end

    ##
    # Initializes the data tables request parameters.
    def initialize(params = {}, &block)
      raise ArgumentError, 'A block is required to return the starting ActiveRecord scope.' unless block_given?

      @data = {}
      @starting_scope = block
      @records = nil

      params = params.symbolize_keys

      if params[:draw]
        @data[:draw] = params[:draw].to_s.to_i
        @data[:start] = params[:start].to_s.to_i
        @data[:length] = params[:length].to_s.to_i

        tmp = params[:search]
        if tmp && tmp[:regex]
          @data[:search] = Regexp.new(tmp)
        elsif tmp
          @data[:search] = tmp.to_s
        end

        tmp = params[:columns]
        @data[:columns] = [ ]
        if tmp
          tmp.each do |col|
            col = col.symbolize_keys

            if col[:search]
              if col[:search][:regex]
                col[:search] = Regexp.new(col[:search][:value])
              else
                col[:search] = col[:search][:value]
              end
            end

            @data[:columns] << col
          end
        end

        tmp = params[:order]
        @data[:order] = { }
        if tmp
          tmp.each do |order|
            order = order.symbolize_keys
            col = columns[order[:column]]
            if col
              @data[:order][col[:name]] = ((order[:dir] || 'asc').downcase).to_sym
            end
          end
        end
      else
        @data[:draw] = :not_provided
      end
    end


    ##
    # Where the data tables parameters provided?
    def provided?
      draw != :not_provided
    end

    ##
    # Gets the records returned by this request.
    def records
      @records ||= get_items_from @starting_scope.call
    end

    ##
    # Gets the total number of records before filtering.
    def records_total
      records
      @data[:records_total]
    end

    ##
    # Gets the total number of records after filtering.
    def records_filtered
      records
      @data[:records_filtered]
    end

    private

    ##
    # Applies the request against an ActiveRecord::Relation object.
    #
    # Returns the results of executing the necessary queries and filters as an array of models.
    def get_items_from(relation, filter_columns = false)

      # store the unfiltered count.
      @data[:records_total] = relation.count

      if filter_columns
        # only get the columns we care about.
        cols = columns.map{|c| (c[:name] || c[:data]).to_s }.reject{|c| c.blank?}
        cols << 'id' unless cols.include?('id')
        relation = relation.select(cols)
      end

      have_regex = search.is_a?(::Regexp) || columns.keep_if{|c| c[:search].is_a?(::Regexp)}.any?

      ###  Database Side Individual Filtering  ###
      columns.reject{|c| c[:search].blank? || c[:search].is_a?(::Regexp)}.each do |col|
        name = (col[:name] || col[:data]).to_s
        unless name.blank?
          relation = relation.where("(UPPER(\"#{name}\") LIKE ?)", "%#{col[:search].upcase}%")
        end
      end

      ###  Database Side Multiple Filtering  ###
      if search.is_a?(::String)
        srch = "%#{search.upcase}%"
        cols = columns.keep_if{|c| c[:searchable]}.map{|c| (c[:name] || c[:data]).to_s }.reject{|c| c.blank?}
        if cols.any?
          relation = relation.where(
              cols.map{|c| "(UPPER(\"#{c}\") LIKE ?)"}.join(' OR '),
              *(cols.map{ srch })
          )
        end
      end

      ###  Database Side Ordering  ###
      if ordering.blank?
        relation = relation.order(id: :asc)
      else
        relation = relation.order(ordering)
      end

      # Now we have two paths, if we have a regex, we need to return everything up to this point and filter with the regular expression(s) before limiting the result set to a specific page.
      # If we don't, then we can simply tell the database to limit the result set and return the results.
      if have_regex
        # execute the query
        relation = relation.to_a

        ###  Local Individual Filtering   ###
        columns.keep_ip{|c| c[:search].is_a?(::Regexp)}.each do |col|
          name = (col[:name] || col[:data]).to_s
          unless name.blank?
            relation = relation.keep_if{|item| !item.respond_to?(name) || item.send(name).to_s =~ col[:search] }
          end
        end

        ###  Local Multiple Filtering  ###
        if search.is_a?(::Regexp)
          columns.keep_if{|c| c[:searchable]}.map{|c| (c[:name] || c[:data]).to_s }.reject{|c| c.blank?}.each do |col|
            relation = relation.keep_if{|item| !item.respond_to?(col) || item.send(col).to_s =~ search }
          end
        end

        # store the filtered count.
        @data[:records_filtered] = relation.count

        # apply limits and return.
        relation = relation[start..-1]
        if length > 0
          relation = relation[0...length]
        end
        relation
      else
        # store the filtered count.
        @data[:records_filtered] = relation.count

        # apply limits and return.
        relation = relation.offset(start)
        if length > 0
          relation = relation.limit(length)
        end
        relation.to_a
      end
    end

  end
end