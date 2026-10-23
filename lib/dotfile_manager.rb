#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require_relative 'bootkit_helpers'
require_relative 'config_manager'

module BootKit
  # DotfileManager handles dotfile setup and management via dotdrop
  class DotfileManager
    include BootKit::Helpers

    # Initialize the DotfileManager
    #
    # @param config_manager [ConfigManager] The configuration manager instance
    # @return [void]
    def initialize(config_manager)
      @config_manager = config_manager
    end

    # Set up dotdrop for dotfile management
    #
    # Installs the dotfiles of the configured dotdrop profile
    #
    # @return [String, nil] Profile name if installation succeeded, nil otherwise
    def setup
      logger.info('Setting up dotdrop for dotfile management...')

      install_dotfiles
    end

    private

    # Install dotfiles using dotdrop
    #
    # @return [String, nil] Profile name if installation succeeded, nil otherwise
    def install_dotfiles
      logger.info('Installing dotfiles with Dotdrop...')
      profile = dotdrop_profile

      logger.info("Using dotdrop profile: #{profile}")
      success = run_dotdrop_installation(profile)

      process_installation_result(success, profile)
    end

    # Get the dotdrop profile from configuration
    #
    # @return [String] The dotdrop profile name
    def dotdrop_profile
      profile = @config_manager.get('dotdrop', 'profile')

      if profile.nil? || profile.to_s.strip.empty?
        logger.error('dotdrop.profile is not set in bootkit.yml — cannot install dotfiles')
        exit(1)
      end

      profile
    end

    # Run the dotdrop installation command
    #
    # @param profile [String] The dotdrop profile to use
    # @return [Boolean] True if installation succeeded, false otherwise
    def run_dotdrop_installation(profile)
      puts "\n--- Dotdrop Output ---"

      success = system('dotdrop', 'install', '-p', profile)

      puts "--- End Dotdrop Output ---\n"
      success
    end

    # Process the result of dotdrop installation
    #
    # @param success [Boolean] Whether the installation succeeded
    # @param profile [String] The dotdrop profile used
    # @return [String, nil] Profile name if installation succeeded, nil otherwise
    def process_installation_result(success, profile)
      unless success
        logger.warn("Dotdrop installation failed with exit code: #{$CHILD_STATUS.exitstatus}")
        return nil
      end

      logger.info('Dotfiles installed successfully.')
      profile
    end
  end
end
