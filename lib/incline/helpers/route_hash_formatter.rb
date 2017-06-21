module Incline::Helpers
  ##
  # A "formatter" that simply collects formatted route data.
  class RouteHashFormatter

    ##
    # Creates a new hash formatter for the route inspector.
    def initialize
      @buffer = []
      @engine = ''
    end

    ##
    # Gets the resulting hash from the route inspector.
    def result
      @buffer
    end

    ##
    # Analyzes the section title to get the current engine name.
    def section_title(title)
      @engine = title.include?(' ') ? title.rpartition(' ')[2] : title
    end

    ##
    # Does nothing for this formatter.
    def header(routes)
      # no need for a header
    end

    ##
    # Does nothing for this formatter.
    def no_routes
      # no need to do anything here either.
    end

    ##
    # Adds the specified routes to the resulting hash.
    def section(routes)
      routes.each do |r|
        @buffer << r.symbolize_keys.merge(engine: @engine)
      end
    end

  end
end