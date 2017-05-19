require 'test_helper'

class MainAppExtensionsTest < ActiveSupport::TestCase

  class TestClass
    class Action2Class
      include Incline::Extensions::MainApp

      def action2
        :action2
      end
    end

    include Incline::Extensions::MainApp

    attr_accessor :called

    def initialize
      self.called = false
    end

    def main_app
      self.called = :main_app
      @main_app ||= Action2Class.new
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

    # and just to be sure, when a class does not define :main_app, we use rails.
    # in this case the fake :main_app doesn't know :root_path and doesn't define
    # its own :main_app, so it calls on rails to execute the method.
    rp = Rails.application.class.routes.url_helpers.root_path
    assert_equal rp, @item.main_app.root_path

  end


end