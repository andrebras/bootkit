#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'bootkit_helpers'

module BootKit
  # ZgenomManager handles Zgenom installation and setup for Zsh plugin management
  class ZgenomManager
    include BootKit::Helpers

    # Check if Zgenom is installed
    #
    # @return [Boolean] true if Zgenom is installed
    def installed?
      Dir.exist?(File.join(Dir.home, '.zgenom'))
    end

    # Set up Zgenom for Zsh plugin management
    #
    # Clones the Zgenom repository if it doesn't exist
    # to enable Zsh plugin management
    #
    # @return [String, nil] Path to zgenom directory if setup succeeded or already installed,
    #                       nil otherwise
    def setup
      logger.info('Setting up Zgenom for Zsh plugin management...')
      zgenom_dir = zgenom_directory

      # Return early if already installed
      if installed?
        logger.info('Zgenom is already installed.')
        return zgenom_dir
      end

      # Install Zgenom
      install_zgenom(zgenom_dir)
    end

    # Get the Zgenom installation directory
    #
    # @return [String] Path to the Zgenom directory
    def zgenom_directory
      File.join(Dir.home, '.zgenom')
    end

    # Install Zgenom by cloning the repository
    #
    # @param zgenom_dir [String] Path to install Zgenom
    # @return [String, nil] Path to zgenom directory if installation succeeded, nil otherwise
    def install_zgenom(zgenom_dir)
      logger.info('Installing Zgenom...')

      if clone_zgenom_repository(zgenom_dir)
        zgenom_dir
      else
        logger.warn('Failed to install Zgenom. Zsh plugin management may not work correctly.')
        nil
      end
    end

    # Clone the Zgenom repository
    #
    # @param zgenom_dir [String] Path to install Zgenom
    # @return [Boolean] True if cloning succeeded, false otherwise
    def clone_zgenom_repository(zgenom_dir)
      system("git clone https://github.com/jandamm/zgenom.git #{zgenom_dir}")
    end
  end
end
