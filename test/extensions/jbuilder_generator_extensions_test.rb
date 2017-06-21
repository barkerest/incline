require 'test_helper'

class JbuilderGeneratorExtensionsTest < ActiveSupport::TestCase

  def setup
    @gen = Rails::Generators::JbuilderGenerator.new [ 'fake_item' ]
  end

  test 'responds to available_views' do
    assert @gen.respond_to?(:available_views, true)
  end

  test 'should have the correct available_views' do
    req = %w(index show _details)
    actual = @gen.send :available_views
    req.each do |view|
      assert actual.include?(view), "Missing '#{view}' view."
    end
  end

end