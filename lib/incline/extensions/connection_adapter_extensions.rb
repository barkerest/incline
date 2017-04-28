module Incline
  ##
  # Adds some extra functionality to database connections.
  module ConnectionAdapterExtension

    ##
    # Searches the database to determine if an object with the specified name exists.
    def object_exists?(object_name)
      safe_name = "'#{object_name.gsub('\'','\'\'')}'"

      sql =
          case self.class.name
            when 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'
              # use sysobjects table.
              "SELECT COUNT(*) AS \"one\" FROM \"sysobjects\" WHERE \"name\"=#{safe_name}"
            when 'ActiveRecord::ConnectionAdapters::SQLite3Adapter'
              # use sqlite_master table.
              "SELECT COUNT(*) AS \"one\" FROM \"sqlite_master\" WHERE (\"type\"='table' OR \"type\"='view') AND (\"name\"=#{safe_name})"
            else
              # query the information_schema TABLES and ROUTINES views.
              "SELECT SUM(Z.\"one\") AS \"one\" FROM (SELECT COUNT(*) AS \"one\" FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME=#{safe_name} UNION SELECT COUNT(*) AS \"one\" FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_NAME=#{safe_name}) AS Z"
          end

      result = exec_query(sql).first

      result && result['one'] >= 1
    end

    ##
    # Executes a stored procedure.
    #
    # For MS SQL Server, this will return the return value from the procedure.
    # For other providers, this is the same as +execute+.
    def exec_sp(stmt)
      case self.class.name
        when 'ActiveRecord::ConnectionAdapters::SQLServerAdapter'
          rex = /^exec(?:ute)?\s+[\["]?(?<PROC>[a-z][a-z0-9_]*)[\]"]?(?<ARGS>\s.*)?$/i
          match = rex.match(stmt)
          if match
            exec_query("DECLARE @SP__RET INTEGER; EXECUTE @SP__RET=[#{match['PROC']}]#{match['ARGS']}; SELECT @SP__RET AS [RET]").first['RET']
          else
            execute stmt
          end
        else
          execute stmt
      end
    end


  end
end

ActiveRecord::ConnectionAdapters::AbstractAdapter.include Incline::ConnectionAdapterExtension
