#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'bootkit_helpers'

module BootKit
  # OnePasswordManager handles 1Password CLI installation and configuration
  class OnePasswordManager
    include BootKit::Helpers

    # Initializes the 1Password manager
    #
    # @return [void]
    def initialize
      # No initialization needed currently
    end

    # Sets up 1Password CLI
    #
    # Installs 1Password CLI if not already installed
    #
    # @return [void]
    def setup
      install_1password_cli
    end

    private

    # Installs 1Password CLI if not already installed
    #
    # Uses Homebrew to install the 1Password CLI tool
    #
    # @return [void]
    def install_1password_cli
      if command_exists?('op')
        logger.info('1Password CLI is already installed.')
        return
      end

      logger.info('1Password CLI (op) not found, installing...')
      result = run_command('brew install --cask 1password-cli')

      unless result[:success]
        logger.error('Failed to install 1Password CLI.')
        exit(1)
      end

      logger.info('1Password CLI installed successfully.')
    end

    # Check if a command exists in the system PATH
    #
    # @param command [String] The command to check
    # @return [Boolean] true if the command exists, false otherwise
    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
  end
end
