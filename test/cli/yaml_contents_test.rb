require 'test_helper'
require 'incline/cli'

class YamlContentsTest < ActiveSupport::TestCase

  ALIGNED_YAML = <<-YAML
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

one:
  alpha: 1
  delta: 4

two:
  bravo: 2
  echo: 5

three:
  charlie: 3
  foxtrot: 6
  YAML

  PRE_REMOVE_YAML = <<-YAML.strip
# Top of file.

one:
  alpha: 1
  delta: 4

two:  # the second section
  bravo: 2
  echo: <%= 'hello' %>  # just a simple embedded ruby command.

three:
  charlie: 3
  foxtrot: 6
  YAML
  
  POST_REMOVE_RESULT = <<-YAML.strip
# Top of file.

one:
  alpha: 1
  delta: 4


three:
  charlie: 3
  foxtrot: 6
  YAML

  POST_POST_REMOVE_RESULT = <<-YAML.strip
# Top of file.

one:
  delta: 4


three:
  charlie: 3
  foxtrot: 6
  YAML

  test 'does not modify unnecessarily on realign' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(ALIGNED_YAML)
    contents.realign!
    assert_equal ALIGNED_YAML, contents.to_s
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
  
  test 'remove_key works as expected' do
    contents = Incline::CliHelpers::Yaml::YamlContents.new(PRE_REMOVE_YAML)
    
    extracted = contents.remove_key %w(two)
    
    assert_equal POST_REMOVE_RESULT, contents.to_s.strip
    
    # there should be three items in the extracted contents.
    assert_equal 3, extracted.length
    
    # the first item should be the base key.
    assert_equal %w(two), extracted[0][:key]
    assert_equal '', extracted[0][:value]
    assert_equal 'the second section', extracted[0][:comment]
    assert extracted[0][:safe]
    
    # followed by bravo.
    assert_equal %w(two bravo), extracted[1][:key]
    assert_equal '2', extracted[1][:value]
    assert_nil extracted[1][:comment]
    assert extracted[1][:safe]
    
    # and finally echo.
    assert_equal %w(two echo), extracted[2][:key]
    assert_equal '<%= \'hello\' %>', extracted[2][:value]
    assert_equal 'just a simple embedded ruby command.', extracted[2][:comment]
    assert extracted[2][:safe]
    
    # one more test just to ensure we can remove subkeys safely.
    extracted = contents.remove_key %w(one alpha)
    
    assert_equal POST_POST_REMOVE_RESULT, contents.to_s.strip
    assert_equal 1, extracted.length
    
    extracted = extracted.first
    assert_equal %w(one alpha), extracted[:key]
    assert_equal '1', extracted[:value]
    assert_nil extracted[:comment]
    assert extracted[:safe]
    
  end

end