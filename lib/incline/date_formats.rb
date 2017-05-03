module Incline
  module DateFormats
    US_DATE_FORMAT = /\A(?<MONTH>\d{1,2})\/(?<DAY>\d{1,2})\/(?<YEAR>(?:\d{2}|\d{4}))(?:\s+(?<HOUR>\d{1,2}):(?<MINUTE>\d{1,2})(?::(?<SECOND>\d{1,2})(?:\.(?<FRACTION>\d+))?)?(?:\s*(?<AMPM>[AP])M?)?)?\z/i
    ALMOST_ISO_DATE_FORMAT = /\A(?<YEAR>\d{2,4})-(?<MONTH>\d{1,2})-(?<DAY>\d{1,2})(?:(T|\s+)(?<HOUR>\d{1,2}):(?<MINUTE>\d{1,2})(?::(?<SECOND>\d{1,2})(?:\.(?<FRACTION>\d+))?)?(?:\s*(?<TZ>(?:Z|[+-]\d{2}:?\d{2})))?)?\z/
  end
end