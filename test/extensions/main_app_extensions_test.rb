require 'test_helper'

class MainAppExtensionsTest < ActiveSupport::TestCase

  class TestClass
    class Action2Class
      def action2
        :action2
      end
    end

    include Incline::MainAppExtension

    attr_accessor :called

    def initialize
      self.called = false
    end

    def main_app
      self.called = :main_app
      Action2Class.new
    end

    def action1
      self.called = :action1
    end

  end

  def setup
    @item = TestClass.new
  end

  test 'main_app should be called automatically' do
    # action1 belongs to the class itself.
    assert_equal :action1, @item.action1
    assert_equal :action1, @item.called

    # action2 belongs to the :main_app object.
    assert_equal :action2, @item.action2
    assert_equal :main_app, @item.called
  end



end