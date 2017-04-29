require 'test_helper'

class WorkPathTest < ActiveSupport::TestCase

  test 'should have a location' do
    assert Incline::WorkPath::location
    assert Dir.exist?(Incline::WorkPath::location)
    path = Incline::WorkPath::path_for 'test.file'

    File.write path, 'Hello World'
    assert File.exist?(path)
    assert_equal 'Hello World', File.read(path)

    File.delete path
    assert_not File.exist?(path)
  end

end