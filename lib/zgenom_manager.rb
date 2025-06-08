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
      zgenom_dir = File.join(Dir.home, '.zgenom')

      if installed?
        logger.info('Zgenom is already installed.')
        return zgenom_dir
      end

      logger.info('Installing Zgenom...')
      unless system("git clone https://github.com/jandamm/zgenom.git #{zgenom_dir}")
        logger.warn('Failed to install Zgenom. Zsh plugin management may not work correctly.')
        return nil
      end

      zgenom_dir
    end
  end
end
