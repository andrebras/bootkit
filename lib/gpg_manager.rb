#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'json'

require_relative 'bootkit_helpers'
require_relative 'config_manager'
require_relative 'key_identifier'
require_relative 'secrets_fetcher'
require_relative 'key_importer'

module BootKit
  # GpgManager handles GPG key management operations
  class GpgManager
    include BootKit::Helpers
    include BootKit::KeyIdentifier
    include BootKit::SecretsFetcher
    include BootKit::KeyImporter

    # Initializes the GPG manager
    #
    # @param config_manager [ConfigManager] The configuration manager instance
    # @return [void]
    def initialize(config_manager)
      @config_manager = config_manager
    end

    # Sets up GPG key from 1Password
    #
    # @return [String, nil] The GPG key ID if setup was successful, nil otherwise
    def setup
      logger.info('Setting up GPG key from 1Password...')

      # Verify dependencies
      return nil unless verify_dependencies

      # Get GPG key from 1Password
      gpg_key = gpg_key_from_1password
      return nil unless gpg_key

      # Import GPG key
      import_gpg_key(gpg_key)
    end

    # Verify that required dependencies are installed
    #
    # @return [Boolean] True if all dependencies are installed, false otherwise
    def verify_dependencies
      # Check if GPG is installed
      unless command_exists?('gpg')
        logger.error('GPG is not installed')
        return false
      end

      # Check if 1Password CLI is installed
      unless command_exists?('op')
        logger.error('1Password CLI is not installed')
        return false
      end

      true
    end
  end
end
