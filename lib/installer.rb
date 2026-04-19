#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require_relative 'bootkit_helpers'
require_relative 'config_manager'
require_relative 'system_manager'
require_relative 'brew_manager'
require_relative 'onepassword_manager'
require_relative 'gpg_manager'
require_relative 'dotfile_manager'
require_relative 'zgenom_manager'

module BootKit
  # Installer handles the main installation process for BootKit
  class Installer
    include BootKit::Helpers

    # Initializes the installer with all required components
    #
    # @return [void]
    def initialize
      @config_manager      = ConfigManager.new
      @gpg_manager         = GpgManager.new(@config_manager)
      @dotfile_manager     = DotfileManager.new(@config_manager, @gpg_manager)
      @system_manager      = SystemManager.new
      @brew_manager        = BrewManager.new
      @zgenom_manager      = ZgenomManager.new
      @onepassword_manager = OnePasswordManager.new
      configure_logging
    end

    # Runs the complete installation process for BootKit
    #
    # Executes all installation steps in sequence:
    # - Verifies macOS environment
    # - Installs Homebrew package manager and packages
    # - Sets up 1Password CLI
    # - Sets up GPG keys from 1Password
    # - Sets up dotdrop for dotfile management
    # - Sets up Zgenom for Zsh plugin management
    #
    # @return [void]
    def run
      @system_manager.setup
      @brew_manager.setup
      @onepassword_manager.setup
      @gpg_manager.setup
      @dotfile_manager.setup
      @zgenom_manager.setup
      setup_bootkit_cli

      logger.info('Installation completed successfully!')
    end

    private

    def setup_bootkit_cli
      local_bin = File.expand_path('~/.local/bin')
      link      = File.join(local_bin, 'bootkit')
      target    = File.expand_path('bin/bootkit')

      FileUtils.mkdir_p(local_bin)
      return logger.info('bootkit CLI already linked') if correct_symlink?(link, target)

      File.unlink(link) if File.exist?(link) || File.symlink?(link)
      File.symlink(target, link)
      logger.info('Linked bootkit CLI → ~/.local/bin/bootkit')
    end

    def correct_symlink?(link, target)
      File.symlink?(link) && File.readlink(link) == target
    end

    def configure_logging
      log_level = @config_manager.get('logging', 'level', default: 'info')
      [@system_manager, @brew_manager, @onepassword_manager, @zgenom_manager,
       @gpg_manager, @dotfile_manager, self].each { |m| m.logger(log_level) }
    end
  end
end
