#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'bootkit_helpers'

module BootKit
  # BrewManager handles Homebrew installation and package management
  class BrewManager
    include BootKit::Helpers

    # Initializes the Homebrew manager
    #
    # @return [void]
    def initialize
    end

    # Sets up Homebrew and installs required packages
    #
    # Installs Homebrew if not already installed
    # Updates Homebrew repositories and installs packages from Brewfile
    #
    # @return [void]
    def setup
      install_homebrew
      install_packages
    end

    private

    # Installs Homebrew package manager if not already installed
    #
    # Detects Apple Silicon vs Intel architecture and configures
    # the appropriate Homebrew environment
    #
    # @return [void]
    def install_homebrew
      if command_exists?('brew')
        logger.info('Homebrew is already installed.')
        return
      end

      logger.info('Installing Homebrew...')

      # Run the installation script
      install_homebrew_script

      # Configure environment based on architecture
      configure_homebrew_environment

      logger.info('Homebrew installed successfully.')
    end

    # Run the Homebrew installation script
    #
    # @return [Boolean] True if installation succeeded
    def install_homebrew_script
      install_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

      unless system(install_cmd)
        logger.error('Failed to install Homebrew.')
        exit(1)
      end

      true
    end

    # Configure Homebrew environment based on system architecture
    #
    # @return [void]
    def configure_homebrew_environment
      if `uname -m`.strip == 'arm64'
        system('eval "$(/opt/homebrew/bin/brew shellenv)"')
      else
        system('eval "$(/usr/local/bin/brew shellenv)"')
      end
    end

    # Updates Homebrew and installs packages from Brewfile
    #
    # Updates Homebrew repositories and installs all packages
    # defined in the project's Brewfile
    #
    # @return [void]
    def install_packages
      logger.info('Updating Homebrew and installing packages...')

      # Update Homebrew
      result = run_command('brew update')
      logger.warn('Failed to update Homebrew, continuing anyway...') unless result[:success]

      # Install packages from Brewfile
      result = run_command('brew bundle')
      unless result[:success]
        logger.error('Failed to install packages from Brewfile.')
        logger.error(result[:stderr])
        exit(1)
      end

      logger.info('Packages installed successfully.')
    end
  end
end
