require 'test_helper'

class ErbScaffoldGeneratorExtensionsTest < ActiveSupport::TestCase

  def setup
    @gen = Erb::Generators::ScaffoldGenerator.new [ 'fake_item' ]
  end

  test 'should have the correct available_views' do
    req = %w(index new edit show _list _form)
    actual = @gen.send :available_views
    req.each do |view|
      assert actual.include?(view), "Missing '#{view}' view."
    end
  end

end