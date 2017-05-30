require 'test_helper'

class ApplicationConfigurationExtensionsTest < ActiveSupport::TestCase

  test 'Rails.application.config has extension' do
    cfg = Rails.application&.config
    skip unless cfg
    assert cfg.respond_to?(:incline_appconfig_original_database_configuration)
  end

  test 'provide default when config missing' do
    cfg = Rails::Application::Configuration.new

    # method must already be defined.
    assert cfg.methods.include?(:incline_appconfig_original_database_configuration)

    # first we'll confirm that the overridden method is getting called.
    silence_warnings do
      def cfg.incline_appconfig_original_database_configuration
        raise 'Just Testing'
      end
    end

    begin
      cfg.database_configuration
      assert false
    rescue
      assert $!.message =~ /just testing/i
    end

    # now we'll pretend there is no configuration file.
    silence_warnings do
      def cfg.incline_appconfig_original_database_configuration
        raise 'Could not load database configuration. No such file - fake/database.yml'
      end
    end

    db_cfg = cfg.database_configuration

    assert db_cfg.is_a?(::Hash)
    assert db_cfg['test']
    assert db_cfg['development']
    assert_nil db_cfg['production']
  end

end