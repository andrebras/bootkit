#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'minitest/pride' # Colorful output
require 'fileutils'
require 'tmpdir'
require 'yaml'

# Path setup
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'bootkit_helpers'
require 'config_manager'

# Test helpers
module TestHelpers
  # Get path to a fixture file
  def fixture_path(filename)
    File.join(File.expand_path('fixtures', __dir__), filename)
  end

  # Create a temporary config file from a fixture
  def create_temp_config_from_fixture(fixture_name)
    temp_dir = Dir.mktmpdir
    fixture_file = fixture_path(fixture_name)
    temp_config_file = File.join(temp_dir, 'bootkit.yml')

    FileUtils.cp(fixture_file, temp_config_file)

    [temp_dir, temp_config_file]
  end

  # Create a temporary config file from data
  def create_temp_config(config_data)
    temp_dir = Dir.mktmpdir
    config_file = File.join(temp_dir, 'bootkit.yml')

    # Create test config
    File.write(config_file, config_data.to_yaml)

    [temp_dir, config_file]
  end

  # Run a block that might call exit, and catch the exit
  def assert_exits(&block)
    # Save original exit method
    original_exit = Kernel.method(:exit)

    begin
      # Override exit to raise an exception instead
      Kernel.define_singleton_method(:exit) do |code|
        raise "Exit called with code: #{code}"
      end

      # Run the block and expect it to raise our custom exception
      assert_raises(RuntimeError, &block)
    ensure
      # Restore original exit method
      Kernel.define_singleton_method(:exit, original_exit)
    end
  end
end
