require 'test_helper'
require 'incline/cli'

class YamlContentsTest < ActiveSupport::TestCase

  CLEAN_YAML = <<-YAML
default: &default
  alpha:    # comment for alpha
  bravo:    # comment for bravo
one:     &one
  charlie:  # comment for charlie
    item_1: :simple                                            # Level 3 remains aligned in all sections.
two:     &two
  delta:
    item_1: "This is a \\"string\\" with a '#' character in it." # A nice long string on level 3.
    item_2: true                                               # Just true.
                                                               # This comment is aligned with the comment above.
three:   &three
  echo:
    item_1: <%= Rails.application.secrets["db"]["password"] %> # Ironically, the same length as the string above.
  YAML

  TOP_OF_FILE = "# Top of file.\n"

  SIMPLE_ADD_KEY_RESULT = <<-YAML.strip
# Top of file.
default:
  one:
    alpha: true
  YAML

  SIMPLE_REPLACE_RESULT = <<-YAML.strip
# Top of file.
default:
  one:
    alpha: false
  YAML

  MULTIPLE_ADD_RESULT = <<-YAML.strip
# Top of file.
three:
  charlie: 3
  foxtrot: 6

two:
  bravo: 2
  echo: 5

one:
  alpha: 1
  delta: 4
  YAML

  test 'does not modify unnecessarily on realign' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(CLEAN_YAML)
    contents.realign!
    assert_equal CLEAN_YAML, contents.to_s
  end

  test 'should insert as appropriate' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(TOP_OF_FILE)
    contents.add_key %w(default one alpha), true
    assert_equal SIMPLE_ADD_KEY_RESULT, contents.to_s.strip
  end

  test 'should replace as appropriate' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(SIMPLE_ADD_KEY_RESULT)
    contents.set_key %w(default one alpha), false
    assert_equal SIMPLE_REPLACE_RESULT, contents.to_s.strip
  end

  test 'multiple add works as expected' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(TOP_OF_FILE)

    contents.add_key %w(one alpha), 1
    contents.add_key %w(two bravo), 2
    contents.add_key %w(three charlie), 3
    contents.add_key %w(one delta), 4
    contents.add_key %w(two echo), 5
    contents.add_key %w(three foxtrot), 6

    assert_equal MULTIPLE_ADD_RESULT, contents.to_s.strip
  end

end