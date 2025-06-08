#!/usr/bin/env ruby
# frozen_string_literal: true

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
      @config_manager = ConfigManager.new
      @system_manager = SystemManager.new
      @brew_manager = BrewManager.new
      @onepassword_manager = OnePasswordManager.new
      @zgenom_manager = ZgenomManager.new

      @gpg_manager = GpgManager.new(@config_manager)
      @dotfile_manager = DotfileManager.new(@config_manager, @gpg_manager)
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

      logger.info('Installation completed successfully!')
    end
  end
end
