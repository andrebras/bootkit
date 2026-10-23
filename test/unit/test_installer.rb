#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'installer'

class TestInstaller < Minitest::Test
  include TestHelpers

  def setup
    # Skip #initialize so no real config, brew, 1Password or gpg is touched
    @installer = BootKit::Installer.allocate
    @installer.logger.level = Logger::FATAL
    @installer.define_singleton_method(:setup_bootkit_cli) { nil }
    %i[system brew onepassword].each { |name| stub_manager(name, true) }
  end

  def test_run_succeeds_when_all_steps_succeed
    %i[gpg dotfile zgenom].each { |name| stub_manager(name, 'ok') }

    @installer.run
  end

  def test_run_exits_when_a_step_fails
    stub_manager(:gpg, 'ok')
    stub_manager(:dotfile, nil)
    stub_manager(:zgenom, 'ok')

    error = assert_raises(SystemExit) { @installer.run }
    assert_equal 1, error.status
  end

  def test_failed_steps_lists_every_failure
    stub_manager(:gpg, nil)
    stub_manager(:dotfile, 'ok')
    stub_manager(:zgenom, nil)

    assert_equal ['GPG import', 'Zgenom'], @installer.send(:failed_steps)
  end

  private

  def stub_manager(name, result)
    manager = Object.new
    manager.define_singleton_method(:setup) { result }
    @installer.instance_variable_set(:"@#{name}_manager", manager)
  end
end
