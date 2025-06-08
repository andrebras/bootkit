#!/usr/bin/env ruby
# frozen_string_literal: true

module BootKit
  # Module for importing GPG keys
  module KeyImporter
    # Import GPG key into the local keyring
    #
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID if import was successful, nil otherwise
    def import_gpg_key(gpg_key)
      # Extract key ID from content
      key_id_value = key_id_from_content(gpg_key)
      return nil unless key_id_value

      # Check if key is already imported
      if key_already_imported?(key_id_value)
        logger.info("GPG key #{key_id_value} is already imported")
        ENV['GPG_KEY_ID'] = key_id_value
        return key_id_value
      end

      # Import key
      logger.info('Importing GPG key...')
      result = perform_key_import(gpg_key)

      # Process import result
      process_import_result(result, key_id_value, gpg_key)
    end

    # Perform the actual key import
    #
    # @param gpg_key [String] The GPG key content
    # @return [Hash] The result of the import command
    def perform_key_import(gpg_key)
      run_command(%w[gpg --import], input: gpg_key)
    end

    # Process the result of a key import
    #
    # @param result [Hash] The result of the import command
    # @param key_id_value [String] The key ID
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID if import was successful, nil otherwise
    def process_import_result(result, key_id_value, gpg_key)
      if result[:success] && key_imported?(result[:stderr])
        logger.info("Successfully imported GPG key #{key_id_value}")
        ENV['GPG_KEY_ID'] = key_id_value
        return key_id_value
      end

      logger.error('Failed to import GPG key')
      logger.debug("GPG key content: #{gpg_key[0..100]}...")
      nil
    end

    # Check if a key is already imported
    #
    # @param key_id [String] The key ID to check
    # @return [Boolean] True if the key is already imported, false otherwise
    def key_already_imported?(key_id)
      result = run_command(['gpg', '--list-secret-keys', key_id])
      result[:success]
    end

    # Check if a key was imported based on GPG output
    #
    # @param output [String] The GPG command output
    # @return [Boolean] True if the key was imported, false otherwise
    def key_imported?(output)
      output.to_s.include?('secret key imported') || output.to_s.include?('secret keys imported')
    end
  end
end
