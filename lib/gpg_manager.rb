#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require 'fileutils'
require 'tmpdir'
require 'json'

require_relative 'bootkit_helpers'
require_relative 'config_manager'

module BootKit
  # GpgManager handles GPG key management operations
  class GpgManager
    include BootKit::Helpers

    # Initializes the GPG manager
    #
    # @param config_manager [ConfigManager] The configuration manager instance
    # @return [void]
    def initialize(config_manager)
      @config_manager = config_manager
    end

    # Sets up GPG by importing keys from 1Password
    #
    # @return [String, nil] The GPG key ID if setup was successful, nil otherwise
    def setup
      logger.info('Setting up GPG key from 1Password...')

      # Check if GPG is installed
      unless command_exists?('gpg')
        logger.error('GPG is not installed. Please install it first.')
        return false
      end

      # Check if 1Password CLI is installed
      unless command_exists?('op')
        logger.error('1Password CLI is not installed. Please install it first.')
        return false
      end

      # Sign in to 1Password if needed
      sign_in_to_1password

      # Get GPG key from 1Password
      gpg_key = gpg_key_from_1password
      return false unless gpg_key

      # Import GPG key
      import_gpg_key(gpg_key)
    end

    # Get key ID from GPG key content
    #
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID or nil if not found
    def key_id_from_content(gpg_key)
      # Try to extract key ID from the key content
      pattern = /-----BEGIN PGP PRIVATE KEY BLOCK-----(.*?)-----END PGP PRIVATE KEY BLOCK-----/m
      match = gpg_key.match(pattern)
      return nil unless match

      # Import key to a temporary keyring to get the ID
      tempdir = Dir.mktmpdir
      begin
        # Create a temporary GNUPGHOME
        env = { 'GNUPGHOME' => tempdir }

        # Import the key to the temporary keyring
        result = run_command(%w[gpg --import], env: env, input: gpg_key)
        return nil unless result[:success]

        # List the keys in the temporary keyring
        result = run_command(%w[gpg --list-secret-keys --with-colons], env: env)
        return nil unless result[:success]

        # Extract the key ID
        key_id_line = result[:stdout].to_s.lines.grep(/^sec/).first
        return nil unless key_id_line

        key_id_line.split(':')[4]
      ensure
        FileUtils.remove_entry_secure(tempdir)
      end
    end

    # Get the GPG key ID from the system's keyring
    #
    # @return [String, nil] The GPG key ID or nil if not found
    def key_id_from_system
      result = run_command(%w[gpg --list-secret-keys --with-colons])
      return nil unless result[:success]

      key_id_line = result[:stdout].to_s.lines.grep(/^sec/).first
      return nil unless key_id_line

      key_id_line.split(':')[4]
    end

    # Find GPG key ID from all available sources (environment, config, system)
    #
    # @return [String, nil] The GPG key ID or nil if not found
    def key_id
      # Try to get the key ID from the environment
      key_id_value = ENV.fetch('GPG_KEY_ID', nil)
      return key_id_value if key_id_value && !key_id_value.empty?

      # Try to get the key ID from the config
      key_id_value = @config_manager.get('gpg', 'key_id')
      return key_id_value if key_id_value && !key_id_value.empty?

      # Try to get the key ID from the system
      key_id_from_system
    end

    private

    # Sign in to 1Password if not already signed in
    #
    # @return [Boolean] true if signed in successfully
    def sign_in_to_1password
      logger.info('Checking 1Password CLI session...')

      # Check if already signed in
      result = run_command('op account list')
      if result[:success]
        logger.info('Already signed in to 1Password')
        return true
      end

      logger.info('Signing in to 1Password...')
      logger.info('Please follow the prompts to sign in to your 1Password account')

      # Run the signin command interactively
      system('op signin')
    end

    # Get GPG key from 1Password
    #
    # @return [String, nil] The GPG key content or nil if retrieval failed
    def gpg_key_from_1password
      logger.info('Retrieving GPG key from 1Password...')

      config = config_from_1password
      item_data = item_from_1password(config[:vault], config[:item_path])
      return nil unless item_data

      gpg_key_from_item(item_data)
    end

    # Get 1Password configuration from config manager
    #
    # @return [Hash] Configuration with vault, item_path, and field
    def config_from_1password
      # Get configuration
      vault = @config_manager.get('onepassword', 'vault', default: 'Dotfiles')
      gpg_key_path = @config_manager.get('onepassword', 'gpg_key_path', default: 'GPG Key/notes')

      # Split the path into item and field
      item_path, field = gpg_key_path.split('/')
      field ||= 'notes'

      logger.info("Looking for GPG key in vault: #{vault}, item: #{item_path}, field: #{field}")

      { vault: vault, item_path: item_path, field: field }
    end

    # Fetch an item from 1Password
    #
    # @param vault [String] The 1Password vault name
    # @param item_path [String] The item path in the vault
    # @return [Hash, nil] The parsed item data or nil if retrieval failed
    def item_from_1password(vault, item_path)
      # Try to get the entire item and extract the notes field
      result = run_command(['op', 'item', 'get', item_path, '--vault', vault, '--format', 'json'])

      unless result[:success]
        logger.error('Failed to retrieve item from 1Password')
        logger.error(result[:stderr])
        return nil
      end

      begin
        JSON.parse(result[:stdout])
      rescue StandardError => e
        logger.error("Failed to parse JSON response: #{e.message}")
        nil
      end
    end

    # Extract GPG key from 1Password item data
    #
    # @param item_data [Hash] The parsed 1Password item data
    # @return [String, nil] The GPG key or nil if not found
    def gpg_key_from_item(item_data)
      # Try to find the notes field in the item data
      if item_data['fields']
        notes_field = item_data['fields'].find do |f|
          f['id'] == 'notesPlain' ||
            f['purpose'] == 'NOTES' ||
            f['label'] == 'notesPlain'
        end

        if notes_field && notes_field['value']
          logger.info('Successfully retrieved GPG key from 1Password')
          return notes_field['value']
        end
      end

      logger.error('Could not find notes field in the 1Password item')
      nil
    end

    # Import GPG key into the local keyring
    #
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID if import was successful, nil otherwise
    def import_gpg_key(gpg_key)
      logger.info('Importing GPG key...')

      # Check if the key is already imported
      key_id_value = key_id_from_content(gpg_key)
      if key_id_value && key_already_imported?(key_id_value)
        logger.info('GPG key is already imported')
        return key_id_value
      end

      # Import the key
      result = run_command(%w[gpg --import], input: gpg_key)

      unless result[:success]
        logger.error('Failed to import GPG key')
        logger.error(result[:stderr])
        return nil
      end

      if key_imported?(result[:stderr])
        logger.info('Successfully imported GPG key')
        # Re-extract the key ID to ensure we return the correct one
        key_id_value || key_id_from_content(gpg_key)
      else
        logger.error("Failed to import GPG key: #{result[:stderr]}")
        nil
      end
    end

    # Check if a key is already imported
    #
    # @param key_id [String] The key ID to check
    # @return [Boolean] True if the key is already imported, false otherwise
    def key_already_imported?(key_id)
      result = run_command(%w[gpg --list-keys --with-colons])
      return false unless result[:success]

      result[:stdout].to_s.include?(key_id)
    end

    # Check if a key was imported based on GPG output
    #
    # @param output [String] The GPG output to check
    # @return [Boolean] True if the key was imported, false otherwise
    def key_imported?(output)
      output.include?('secret key imported') ||
        output.include?('secret keys read') ||
        output.include?('not changed')
    end
  end
end
