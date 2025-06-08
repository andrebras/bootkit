#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'

class TestBootkitHelpers < Minitest::Test
  class HelperTester
    include BootKit::Helpers
  end

  def setup
    @helper = HelperTester.new
  end

  def test_logger_creation
    assert_instance_of Logger, @helper.logger
  end

  def test_ensure_directory
    temp_dir = Dir.mktmpdir
    test_dir = File.join(temp_dir, 'test_dir')

    # Directory shouldn't exist yet
    refute File.directory?(test_dir)

    # Create directory
    @helper.ensure_directory(test_dir)

    # Directory should exist now
    assert File.directory?(test_dir)

    # Should not error when directory already exists
    @helper.ensure_directory(test_dir)

    FileUtils.remove_entry temp_dir
  end

  def test_command_exists_mock
    # Mock the run_command method to test command_exists?
    def @helper.run_command(cmd, _options = {})
      if ['which git', %w[which git]].include?(cmd)
        { success: true }
      else
        { success: false }
      end
    end

    assert @helper.command_exists?('git')
    refute @helper.command_exists?('nonexistent-command')
  end
end
