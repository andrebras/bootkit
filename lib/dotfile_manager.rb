#!/usr/bin/env ruby
# frozen_string_literal: true

require 'English'
require_relative 'bootkit_helpers'
require_relative 'config_manager'
require_relative 'gpg_manager'

module BootKit
  # DotfileManager handles dotfile setup and management via dotdrop
  class DotfileManager
    include BootKit::Helpers

    # Initialize the DotfileManager
    #
    # @param config_manager [ConfigManager] The configuration manager instance
    # @param gpg_manager [GpgManager] The GPG manager instance
    # @return [void]
    def initialize(config_manager, gpg_manager)
      @config_manager = config_manager
      @gpg_manager = gpg_manager
    end

    # Set up dotdrop for dotfile management
    #
    # Uses the GPG key ID from GpgManager to configure dotdrop
    # for dotfile installation with the specified profile
    #
    # @return [Boolean] true if setup succeeded
    def setup
      logger.info('Setting up dotdrop for dotfile management...')

      gpg_key_id = @gpg_manager.key_id

      if gpg_key_id.nil? || gpg_key_id.empty?
        logger.warn('Failed to get GPG key ID. Dotfile encryption/decryption may fail.')
      else
        logger.info("Using GPG key ID: #{gpg_key_id}")
        ENV['GPG_KEY_ID'] = gpg_key_id
      end

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

      success = system(
        { 'GPG_KEY_ID' => ENV.fetch('GPG_KEY_ID', nil) },
        'dotdrop',
        'install',
        '-p',
        profile
      )

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
