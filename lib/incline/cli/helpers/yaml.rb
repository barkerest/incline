module Incline
  module CliHelpers

    ##
    # Adds YAML text helper methods.
    #
    # Does not parse YAML files, but does allow for updating raw text files to be YAML compliant.
    module Yaml

      class YamlError < ::Incline::CLI::CliError; end

      ##
      # Helper class to process the YAML file contents easily.
      class YamlContents

        ##
        # Creates a new YAML contents.
        def initialize(content)
          @content = content.to_s.gsub("\r\n", "\n").strip + "\n"
        end

        ##
        # Returns the YAML contents.
        def to_s
          @content
        end

        ##
        # Adds a key to the YAML contents if it is missing.
        # Does nothing to the key if it exists.
        #
        #   add_key [ "default", "name" ], "george"
        #
        # The 'key' should be an array defining the path.
        #
        # Value can be nil, a string, a symbol, a number, or a boolean.
        #
        # The 'make_safe_value' option can be used to provide an explicit text value.
        # This can be useful if you want to add a specific value, like an ERB command.
        #
        #   add_key [ "default", "name" ], "<%= ENV[\"DEFAULT_USER\"] %>", false
        #
        # You can also use a hash for the value to specify advanced options.
        # Currently only three advanced options are recognized.
        #
        # The first option, :value, simply sets the value.  If this is the only
        # hash key provided, then the value supplied is treated as if it was the original
        # value.  In other words, only setting :value is the same as not using a hash and
        # just passing in the value, so the value must be nil, a string, a symbol, a number,
        # or a boolean.
        #
        # The second option, :safe, works the opposite of the 'make_safe_value' parameter.
        # If :safe is a non-false value, then it is like 'make_safe_value' is set to false.
        # If :safe is a false value, then it is like 'make_safe_value' is set to true.
        # The :safe value can be set to true and the :value option can set the value, or
        # the :safe value can be set to the value directly since all strings are non-false.
        #
        # The third option, :before_default, tells add_key to insert the section before the
        # 'default' section (if the section doesn't exist).  This can be useful if the 'default'
        # section is going to be referencing the key you are adding.  Otherwise, when a
        # section needs to be added, it gets added right after the 'default' section ends.
        #
        # That means if you are adding a number of sections, they will be added in reverse order.
        #
        #     contents.add_key [ "three", "abc" ], 123
        #     contents.add_key [ "two", "abc" ], 123
        #     contents.add_key [ "one", "abc" ], 123
        #
        #     one:
        #       abc: 123
        #     two:
        #       abc: 123
        #     three:
        #       abc: 123
        #
        # Returns the contents object.
        def add_key(key, value, make_safe_value = true)

          # ensure the parent structure exists!
          if key.count > 1
            add_key(key[0...-1], nil)
          else
            # If the base key already exists, no need to look further.
            return self if @content =~ /^#{key.first}:/

            unless @content[0] == '#'
              @content = "# File modified by Incline v#{Incline::VERSION}.\n" + @content
            end
          end

          val_name = key.last

          # construct a regular expression to find the parent group and value.
          rex_str = '^('
          rex_prefix = /\A./
          key.each_with_index do |attr,level|
            lev = (level < 1 ? '' : ('\\s\\s' * (level)))
            if lev != ''
              rex_str += '(?:' + lev + '[^\\n]*\\n)*'
            end
            if level == key.count - 1
              if level == 0
                # at level 0, make the "parent" any leading comments or blank lines in the file.
                # and as a special check, if the current attr is not "default" and "default" exists, make sure it comes first
                # as well.  However, we can specify the :before_default value option to put this top level before default.
                #
                # notice we swap the start of line anchor with the start of string anchor.
                rex_str =
                    if attr != 'default' && @content =~ /^default:/ && !(value.is_a?(::Hash) && value[:before_default])
                      '\\A((?:\\s*(?:#.*)?\\n)+default:.*\\n(?:\\s\\s.*\\n)*(?:\\s*\\n)*'
                    else
                      '\\A((?:\\s*(?:#.*)?\\n)+'
                    end
              end
              rex_str += ')'
              rex_prefix = Regexp.new(rex_str)
              rex_str += '(' + lev + attr + ':.*\\n)'
            else
              rex_str += lev + attr + ':.*\\n'
            end
          end

          rex = Regexp.new(rex_str)

          if @content =~ rex
            # all good.
          elsif @content =~ rex_prefix
            if make_safe_value
              value = safe_value(value)
              value = add_value_offset(key, value)
            elsif value.is_a?(::Hash)
              value = value[:value]
            end
            value = '' if value =~ /\A\s*\z/
            # should be true thanks to first step in this method.
            # capture 1 would be the parent group.
            rep = "\\1#{'  ' * (key.count - 1)}#{val_name}:#{value}\n"
            rep += "\n" if key.count == 1
            @content.gsub! rex_prefix, rep
          else
            raise ::Incline::CliHelpers::Yaml::YamlError, "Failed to create parent group for '#{key.join('/')}'."
          end

          self
        end


        ##
        # Adds a key to the YAML contents if it is missing.
        # Does nothing to the key if it exists.
        #
        #   add_key_with_comment [ "default", "name" ], "george", "this is the name of the default user"
        #
        # The 'key' should be an array defining the path.
        #
        # Value can be nil, a string, a symbol, a number, or a boolean.
        # Value can also be a hash according to #add_key.
        #
        # Returns the contents object.
        def add_key_with_comment(key, value, comment)
          add_key key, value_with_comment(key, value, comment), false
        end

        ##
        # Sets a key in the YAML contents.
        # Adds the key if it is missing, replaces it if it already exists.
        #
        #   set_key [ "default", "name" ], "george"
        #
        # The 'key' should be an array defining the path.
        #
        # Value can be nil, a string, a symbol, a number, or a boolean.
        # Value can also be a hash according to #add_key.
        #
        # The 'make_safe_value' option can be used to provide an explicit text value.
        # This can be useful if you want to add a specific value, like an ERB command.
        #
        #   set_key [ "default", "name" ], "<%= ENV[\"DEFAULT_USER\"] %>", false
        #
        # Returns the contents object.
        def set_key(key, value, make_safe_value = true)

          # construct a regular expression to find the value and not confuse it with any other value in the file.
          rex_str = '^('
          key.each_with_index do |attr,level|
            lev = (level < 1 ? '' : ('\\s\\s' * (level)))
            if lev != ''
              rex_str += '(?:' + lev + '.*\\n)*'
            end
            if level == key.count - 1
              rex_str += lev + attr + ':)\\s*([^#\\n]*)?(#[^\\n]*)?\\n'
            else
              rex_str += lev + attr + ':.*\\n'
            end
          end

          rex = Regexp.new(rex_str)

          if @content =~ rex
            if make_safe_value
              value = safe_value(value)
              value = add_value_offset(key, value)
            elsif value.is_a?(::Hash)
              value = value[:value]
            end
            value = '' if value =~ /\A\s*\z/
            # Capture 1 is everything before the value.
            # Capture 2 is going to be just the value.
            # Capture 3 is the comment (if any).  This allows us to propagate comments if we change a value.
            if $2 != value
              rep = "\\1#{value}\\3\n"
              @content.gsub! rex, rep
            end

            self
          else
            add_key(key, value, make_safe_value)
          end
        end

        ##
        # Sets a key in the YAML contents.
        # Adds the key if it is missing, replaces it if it already exists.
        #
        #   set_key_with_comment [ "default", "name" ], "george", "this is the name of the default user"
        #
        # The 'key' should be an array defining the path.
        #
        # Value can be nil, a string, a symbol, a number, or a boolean.
        # Value can also be a hash according to #add_key.
        #
        # Returns the contents object.
        def set_key_with_comment(key, value, comment)
          set_key key, value_with_comment(key, value, comment), false
        end

        ##
        # Realigns the file.
        #
        # All values and comments will line up at each level when complete.
        def realign!
          # match 1 = lead white
          # ([ \t]*)
          # match 2 = key name
          # (\S+):
          # match 3 = value with leading whitespace
          # ((?:[ \t]*(?:"(?:[^"]*(?:(?:\\{1}|\\{3}|\\{5}|\\{7}|\\{9})")?)*"|'(?:[^']*(?:(?:\\{1}|\\{3}|\\{5}|\\{7}|\\{9})')?)*'|[^\s#"']+))*)
          # ignore white between value and comment (if any).
          # [ \t]*
          # match 4 = comment (if any).
          # (?:#([^\n]*))?
          line_regex = /\A([ \t]*)(\S+):((?:[ \t]*(?:"(?:[^"]*(?:(?:\\{1}|\\{3}|\\{5}|\\{7}|\\{9})")?)*"|'(?:[^']*(?:(?:\\{1}|\\{3}|\\{5}|\\{7}|\\{9})')?)*'|[^\s#"']+))*)[ \t]*(?:#([^\n]*))?\z/
          last_level = 0
          lines = @content.split("\n").map do |raw_line|
            # assuming the file is valid any lines not matching the regex should be comments or blank.
            match = line_regex.match(raw_line)
            if match    # a key: value line
              last_level = (match[1].length / 2).to_i + 1 # one level per 2 spaces.
              {
                  level: last_level,
                  key: match[2].strip,
                  value: match[3] ? match[3].strip : nil,
                  comment: match[4] ? match[4].lstrip : nil
              }
            elsif raw_line =~ /\A(\s*)#(.*)\z/    # a comment
              whitespace = $1
              raw_line = $2
              level =
                  if whitespace.length >= (last_level * 2)
                    last_level
                  else
                    (whitespace.length / 2).to_i + 1
                  end
              raw_line = raw_line[1..-1] if raw_line[0] == ' '
              {
                  level: level,
                  comment: raw_line
              }
            else
              {
                  level: 0,
                  value: raw_line
              }
            end
          end

          # reset the offsets.
          value_offsets.clear
          comment_offsets.clear

          # get value offsets.
          lines.each do |line|
            level = line[:level]
            if level > 0 && line[:key]
              key_len = line[:key].length + 2   # include the colon and a space
              if key_len > level_value_offset(level)
                set_level_value_offset level, key_len
              end
            end
          end

          # get comment offsets.
          lines.each do |line|
            level = line[:level]
            if level > 0 && line[:value]
              voff = level_value_offset(level)
              val_len = line[:value] ? line[:value].length : 0
              coff = voff + val_len + 1         # add a space after the value.
              if coff > level_comment_offset(level)
                set_level_comment_offset level, coff
              end
            end
          end

          # convert the lines back into strings with proper spacing.
          lines = lines.map do |line|
            level = line[:level]
            if level > 0
              if line[:key]
                # a key: value line.
                key = line[:key] + ':'
                key = key.ljust(level_value_offset(level), ' ') unless line[:value].to_s == '' && line[:comment].to_s == ''
                val = line[:value].to_s
                val = val.ljust(level_comment_offset(level) - level_value_offset(level), ' ') unless line[:comment].to_s == ''
                comment = line[:comment] ? "# #{line[:comment]}" : ''
                ('  ' * (level - 1)) + key + val + comment
              else
                # just a comment line.
                ('  ' * (level - 1)) +
                    (' ' * level_comment_offset(level)) +
                    "# #{line[:comment]}"
              end
            else
              line[:value]  # return the original value
            end
          end

          @content = lines.join("\n") + "\n"
        end

        ##
        # Gets the value offset for the specified level.
        #
        # The offset is based on the beginning of the level in question.
        # There will always be at least one whitespace before the value.
        # For instance an offset of 10 for level 2 would be like this:
        #
        #   one:
        #     two:      value
        #     some_long_name: value
        #   # 0123456789^
        #
        def level_value_offset(level)
          value_offsets[level] || 0
        end

        ##
        # Sets the value offset for the specified level.
        #
        # The offset is based on the beginning of the level in question.
        # There will always be at least one whitespace before the value.
        # For instance an offset of 10 for level 2 would be like this:
        #
        #   one:
        #     two:      value
        #     some_long_name: value
        #   # 0123456789^
        #
        def set_level_value_offset(level, offset)
          value_offsets[level] = offset
        end

        ##
        # Gets the comment offset for the specified level.
        #
        # The offset is based on the beginning of the level in question.
        # There will always be at least one whitespace before the value
        # and at least one whitespace between the value and a comment.
        # For instance an offset of 15 for level 2 would be like this:
        #
        #   one:
        #     two: value     # comment
        #     some_long_name: value # comment
        #   # 012345678901234^
        #
        def level_comment_offset(level)
          comment_offsets[level] || 0
        end

        ##
        # Sets the comment offset for the specified level.
        #
        # The offset is based on the beginning of the level in question.
        # There will always be at least one whitespace before the value
        # and at least one whitespace between the value and a comment.
        # For instance an offset of 15 for level 2 would be like this:
        #
        #   one:
        #     two: value     # comment
        #     some_long_name: value # comment
        #   # 012345678901234^
        #
        def set_level_comment_offset(level, offset)
          comment_offsets[level] = offset
        end

        ##
        # Allows comparing the contents against a regular expression.
        def =~(regexp)
          @content =~ regexp
        end

        private

        def value_with_comment(key, value, comment)
          vh = value.is_a?(::Hash) ? value : { safe: false, value: value, before_default: false }
          unless vh[:safe]
            vh[:value] = add_comment(key, add_value_offset(key, safe_value(vh[:value])), comment)
            vh[:safe] = true
          end
          vh
        end

        def add_value_offset(key, safe_value)
          key_len = key.last.to_s.length + 1 # add one for the colon.
          voff = level_value_offset(key.count) - key_len
          voff = 1 if voff < 1

          (' ' * voff) + safe_value
        end

        def add_comment(key, safe_value, comment)
          key_len = key.last.to_s.length + 1 # add one for the colon.
          coff = level_comment_offset(key.count) - key_len - safe_value.length
          coff = 1 if coff < 1
          coff_total = ((key.count - 1) * 2) + value.length + coff

          safe_value + (' ' * coff) + '# ' + comment.to_s.gsub("\r\n", "\n").gsub("\n", "\n#{' ' * coff_total}# ")
        end

        def value_offsets
          @value_offsets ||= [ ]
        end

        def comment_offsets
          @comment_offsets ||= [ ]
        end

        # always returns a string, even for safe values.
        def safe_value(value)
          # Allows the user to specify the value as a hash option without marking it as safe.
          if value.is_a?(::Hash) && value[:value] && !value[:safe]
            value = value[:value]
          end

          if value.is_a?(::Hash) && value[:safe]
            # If the user specifies a safe value, return it as-is.
            (value[:value] || value[:safe]).to_s
          elsif value.nil?
            # If the value is nil, return an empty string.
            ''
          else
            # Otherwise process the value to make it YAML compliant.
            unless value.is_a?(::String) || value.is_a?(::Symbol) || value.is_a?(::Numeric) || value.is_a?(::TrueClass) || value.is_a?(::FalseClass)
              raise ArgumentError, "'value' must be a value type (string, symbol, number, boolean)"
            end

            if value.is_a?(::String)
              if value =~ /\A\s*\z/m  ||                # Empty or filled with whitespace
                  value =~ /\A\s/m    ||                # Starts with whitespace
                  value =~ /\s\z/m    ||                # Ends with whitespace
                  value =~ /\A[+-]?\d+(\.\d*)?\z/ ||    # Contains a probable number
                  value =~ /\A0(b[01]*|x[0-9a-f]*)\z/i  # Another probable number in binary or hex format.
                value.inspect
              elsif value =~ /\A([0-9]*[a-z]|[a-z])([a-z0-9_ .,=-]*[a-z0-9_])*\z/i
                value
              else
                value.inspect
              end
            else
              value.inspect
            end
          end

        end

      end

      protected

      ##
      # Repairs a YAML file, creating it if necessary.
      #
      # The optional parameters define what all will be done by this method before yielding to a supplied block.
      # The contents of the YAML file are yielded to the block and the block should return the modified contents.
      #
      #     repair_yaml "config/database.yml" do |contents|
      #       contents.add_key [ "test", "database" ], "db/test.sqlite3"
      #     end
      #
      # If 'env_ref_set' is set to a non-empty value, then it defines the anchor providing default values
      # for the environment sections.  The default value is 'default'.
      #
      # If 'ensure_default' is set, then a 'default' section with a 'default' anchor will be created at the
      # beginning of the file unless a 'default' section already exists in the file.
      # The default value is 'true'.
      #
      # If 'ensure_env' is set, then the environment sections will be created if missing.  This ensures that
      # a 'development', 'test', and 'production' section all exist. The default value is 'true'.
      #
      # If 'realign' is set, then the entire file will be processed.  All values will be aligned at each
      # level and so will all comments.  The default is 'true'.
      #
      # The default options on an empty file will generate a 'default' section before yielding and then
      # fill in the environment sections after the block returns.
      #
      #     default: &default
      #
      #     development:
      #       <<: *default
      #
      #     test:
      #       <<: *default
      #
      #     production:
      #       <<: *default
      #
      def repair_yaml(filename, env_ref_sect = 'default', ensure_default = true, ensure_env = true, realign = true) # :doc:
        dirty = false
        stat = :updated

        # ensure the file exists.
        unless File.exist?(filename)
          File.write filename, "# File created by Incline v#{Incline::VERSION}.\n"
          stat = :created
          dirty = true
        end

        orig_contents = File.read(filename)

        contents = YamlContents.new(orig_contents)

        if ensure_default
          contents.set_key %w(default), '&default', false
        end

        yield contents if block_given?

        if ensure_env
          %w(development test production).each do |sect|
            contents.add_key [ sect ], nil
          end
        end

        # Potential bug, and I'm not even sure if it would be or not.
        # But since we use relatively simple regular expressions to perform the set action,
        # the << "key" can only exist once and would be overridden.
        # That means that a section would not be able to include multiple anchors.
        # Like I said before, I'm not sure if that would actually be a bug or not.
        #
        # Luckily, the YAML files aren't meant to be overly complex so this shouldn't show
        # up regularly if at all.
        unless env_ref_sect.to_s.strip == ''
          %w(development test production).each do |sect|
            contents.set_key [ sect, '<<' ], '*' + env_ref_sect
          end
        end

        contents.realign! if realign

        unless dirty
          dirty = (orig_contents != contents.to_s)
        end

        if dirty
          File.write filename, contents.to_s
          say_status stat, filename, :green
        else
          say_status :unchanged, filename, :blue
        end
      end



    end
  end
end