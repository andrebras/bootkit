#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'

module BootKit
  # Module for retrieving secrets from password stores
  module SecretsFetcher
    # Check authentication status with 1Password CLI
    #
    # @return [Boolean] True if authenticated, false otherwise
    def signed_in_to_1password?
      result = run_command(%w[op whoami])

      if result[:success]
        logger.info('Authenticated with 1Password')
        return true
      end

      logger.error('Not authenticated with 1Password. Please sign in via the 1Password desktop app.')
      false
    end

    # Get GPG key from 1Password
    #
    # @return [String, nil] The GPG key or nil if not found
    def gpg_key_from_1password
      return nil unless signed_in_to_1password?

      config = config_from_1password
      return nil unless config

      item_data = item_from_1password(config[:vault], config[:gpg_key_path])
      return nil unless item_data

      gpg_key_from_item(item_data)
    end

    # Get configuration for 1Password GPG key retrieval
    #
    # @return [Hash, nil] Configuration hash or nil if not found
    def config_from_1password
      vault = @config_manager.get('onepassword', 'vault', default: 'Dotfiles')
      gpg_key_path = @config_manager.get('onepassword', 'gpg_key_path', default: 'GPG Key/notes')

      unless vault && gpg_key_path
        logger.error('1Password vault or GPG key path not configured')
        return nil
      end

      { vault: vault, gpg_key_path: gpg_key_path }
    end

    # Get item from 1Password
    #
    # @param vault [String] The 1Password vault name
    # @param item_path [String] The path to the item in the vault
    # @return [Hash, nil] The parsed item data or nil if not found
    def item_from_1password(vault, item_path)
      # Split item path into item name and field
      item_parts = item_path.split('/')
      item_name = item_parts[0]

      # Get item from 1Password
      result = run_command(['op', 'item', 'get', item_name, '--vault', vault, '--format', 'json'])
      return nil unless result[:success]

      begin
        JSON.parse(result[:stdout])
      rescue JSON::ParserError
        logger.error('Failed to parse 1Password response')
        nil
      end
    end

    # Extract GPG key from 1Password item data
    #
    # @param item_data [Hash] The parsed 1Password item data
    # @return [String, nil] The GPG key or nil if not found
    def gpg_key_from_item(item_data)
      notes_field = find_notes_field(item_data)

      if notes_field && notes_field['value']
        logger.info('Successfully retrieved GPG key from 1Password')
        return notes_field['value']
      end

      logger.error('Could not find notes field in the 1Password item')
      nil
    end

    # Find the notes field in 1Password item data
    #
    # @param item_data [Hash] The parsed 1Password item data
    # @return [Hash, nil] The notes field or nil if not found
    def find_notes_field(item_data)
      return nil unless item_data['fields']

      item_data['fields'].find do |f|
        f['id'] == 'notesPlain' || f['purpose'] == 'NOTES' || f['label'] == 'notesPlain'
      end
    end
  end
end
