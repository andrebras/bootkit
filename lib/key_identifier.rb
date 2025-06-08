#!/usr/bin/env ruby
# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'

module BootKit
  # Module for identifying and extracting GPG key IDs
  module KeyIdentifier
    # Get key ID from GPG key content
    #
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID or nil if not found
    def key_id_from_content(gpg_key)
      # Try to extract key ID from the key content
      pattern = /-----BEGIN PGP PRIVATE KEY BLOCK-----(.*?)-----END PGP PRIVATE KEY BLOCK-----/m
      match = gpg_key.match(pattern)
      return nil unless match

      # Create a temporary keyring and extract the key ID
      with_temp_gpg_home do |tempdir|
        extract_key_id_from_temp_keyring(gpg_key, tempdir)
      end
    end

    # Create a temporary GPG home directory and yield to the block
    #
    # @param block [Block] Block to execute with the temporary directory
    # @return [Object] Result of the block
    def with_temp_gpg_home
      tempdir = Dir.mktmpdir
      result = yield(tempdir)
      result
    ensure
      FileUtils.remove_entry_secure(tempdir) if tempdir
    end

    # Extract key ID from a temporary GPG keyring
    #
    # @param gpg_key [String] The GPG key content
    # @param tempdir [String] Path to temporary GPG home directory
    # @return [String, nil] The key ID or nil if extraction failed
    def extract_key_id_from_temp_keyring(gpg_key, tempdir)
      # Create a temporary GNUPGHOME
      env = { 'GNUPGHOME' => tempdir }

      # Import the key to the temporary keyring
      result = run_command(%w[gpg --import], env: env, input: gpg_key)
      return nil unless result[:success]

      # List the keys in the temporary keyring
      result = run_command(%w[gpg --list-secret-keys --with-colons], env: env)
      return nil unless result[:success]

      # Extract the key ID
      extract_key_id_from_output(result[:stdout])
    end

    # Extract key ID from GPG output
    #
    # @param output [String] GPG command output
    # @return [String, nil] The key ID or nil if not found
    def extract_key_id_from_output(output)
      key_id_line = output.to_s.lines.grep(/^sec/).first
      return nil unless key_id_line

      key_id_line.split(':')[4]
    end

    # Get the GPG key ID from the system's keyring
    #
    # @return [String, nil] The GPG key ID or nil if not found
    def key_id_from_system
      result = run_command(%w[gpg --list-secret-keys --with-colons])
      return nil unless result[:success]

      extract_key_id_from_output(result[:stdout])
    end

    # Get the GPG key ID from environment or system
    #
    # @return [String, nil] The GPG key ID or nil if not found
    def key_id
      # Check if key ID is already set in environment
      env_key_id = ENV.fetch('GPG_KEY_ID', nil)
      return env_key_id if env_key_id && !env_key_id.empty?

      # Try to get key ID from system
      system_key_id = key_id_from_system
      return system_key_id if system_key_id

      nil
    end
  end
end
