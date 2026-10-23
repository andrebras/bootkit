#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'installer'

class TestInstaller < Minitest::Test
  include TestHelpers

  def setup
    # Skip #initialize so no real config, brew or dotdrop is touched
    @installer = BootKit::Installer.allocate
    @installer.logger.level = Logger::FATAL
    @installer.define_singleton_method(:setup_bootkit_cli) { nil }
    %i[system brew].each { |name| stub_manager(name, true) }
  end

  def test_run_succeeds_when_all_steps_succeed
    %i[dotfile zgenom].each { |name| stub_manager(name, 'ok') }

    @installer.run
  end

  def test_run_exits_when_a_step_fails
    stub_manager(:dotfile, nil)
    stub_manager(:zgenom, 'ok')

    error = assert_raises(SystemExit) { @installer.run }
    assert_equal 1, error.status
  end

  def test_run_changes_to_repo_root
    %i[dotfile zgenom].each { |name| stub_manager(name, 'ok') }

    Dir.chdir(Dir.tmpdir) do
      @installer.run

      assert_equal File.realpath(BootKit::Installer::ROOT_DIR), File.realpath(Dir.pwd)
    end
  end

  def test_root_dir_holds_bootkit_cli
    assert File.executable?(File.join(BootKit::Installer::ROOT_DIR, 'bin', 'bootkit'))
  end

  def test_failed_steps_lists_every_failure
    stub_manager(:dotfile, nil)
    stub_manager(:zgenom, nil)

    assert_equal %w[Dotfiles Zgenom], @installer.send(:failed_steps)
  end

  private

  def stub_manager(name, result)
    manager = Object.new
    manager.define_singleton_method(:setup) { result }
    @installer.instance_variable_set(:"@#{name}_manager", manager)
  end
end
