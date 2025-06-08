#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

class TestConfigManager < Minitest::Test
  include TestHelpers

  def setup
    @temp_dir, @config_file = create_temp_config_from_fixture('bootkit.test.yml')
    @config_manager = BootKit::ConfigManager.new(@config_file)
  end

  def teardown
    FileUtils.remove_entry @temp_dir if @temp_dir && File.directory?(@temp_dir)
  end

  def test_get_config_value
    assert_equal 'Test', @config_manager.get('onepassword', 'vault')
    assert_equal 'GPG/notes', @config_manager.get('onepassword', 'gpg_key_path')
    assert_equal 'TEST-PROFILE', @config_manager.get('dotdrop', 'profile')
    assert_equal 'info', @config_manager.get('logging', 'level')
  end

  def test_get_with_default
    assert_equal 'default', @config_manager.get('missing', 'key', default: 'default')
  end

  def test_get_nested_default
    assert_equal 'default', @config_manager.get('onepassword', 'missing', default: 'default')
  end

  def test_get_with_nil_default
    assert_nil @config_manager.get('missing', 'key')
  end

  def test_custom_config_path
    # Create a different config file
    custom_config = {
      'custom' => {
        'setting' => 'custom_value'
      }
    }

    temp_dir = Dir.mktmpdir
    custom_config_path = File.join(temp_dir, 'custom_config.yml')
    File.write(custom_config_path, custom_config.to_yaml)

    # Create config manager with custom path
    custom_manager = BootKit::ConfigManager.new(custom_config_path)

    # Test that it loaded the custom config
    assert_equal 'custom_value', custom_manager.get('custom', 'setting')

    # Clean up
    FileUtils.remove_entry temp_dir
  end
end
