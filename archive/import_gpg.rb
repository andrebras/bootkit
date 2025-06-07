#!/usr/bin/env ruby
# frozen_string_literal: true

# GPG Key Import Script
#
# This script imports a GPG key from 1Password into the local GPG keyring.
# It is designed to be idempotent, meaning it will only import the key if it
# is not already present in the keyring.
#
# Features:
# - Authenticates with 1Password CLI
# - Retrieves GPG key from a secure note in 1Password
# - Extracts key identifier using multiple patterns
# - Checks if key is already imported before importing
# - Handles errors gracefully with informative messages
#
# Usage:
#   ./import_gpg.rb
#
# Requirements:
#   - 1Password CLI (op) must be installed and configured
#   - GPG must be installed
#   - A secure note with GPG key must exist in 1Password

require_relative '../lib/bootkit_helpers'
require 'yaml'

# ImportGpg handles importing GPG keys from 1Password
class ImportGpg
  include BootKit::Helpers
  
  # Initialize with configuration
  def initialize
    @config = load_config
    
    # Set configuration values with defaults
    @op_vault = @config.dig('onepassword', 'vault') || 'Dotfiles'
    @op_gpg_key_path = @config.dig('onepassword', 'gpg_key_path') || 'GPG Key/notes'
    @gpg_key_id = @config.dig('gpg', 'key_id')
    
    # Set log level if specified
    if @config.dig('logging', 'level')
      level = @config.dig('logging', 'level').to_s.upcase
      logger.level = Logger.const_get(level) if Logger.constants.include?(level.to_sym)
    end
  end
  
  # Load configuration from YAML file
  #
  # @return [Hash] Configuration values
  def load_config
    config_path = File.join(File.dirname(__FILE__), '..', 'bootkit.yml')
    example_path = File.join(File.dirname(__FILE__), '..', 'bootkit.example.yml')
    
    # If bootkit.yml doesn't exist but example does, copy it
    if !File.exist?(config_path) && File.exist?(example_path)
      require 'fileutils'
      FileUtils.cp(example_path, config_path)
      logger.info("Created bootkit.yml from example. You may want to review and customize it.")
    end
    
    # Load and return the config, or empty hash if file doesn't exist
    return {} unless File.exist?(config_path)
    
    begin
      YAML.load_file(config_path) || {}
    rescue => e
      logger.error("Error loading configuration: #{e.message}")
      {}
    end
  end
  
  # Signs in to 1Password CLI and sets the session token
  #
  # @return [Boolean] true if sign-in was successful, false otherwise
  def signin_to_1password
    logger.info('Signing in to 1Password CLI...')
    
    # Use system to run the command directly to allow interactive input
    if system('op signin')
      true
    else
      logger.error('Failed to sign in to 1Password')
      false
    end
  end

  # Retrieves the GPG key from 1Password
  #
  # @return [String, nil] The GPG key content or nil if retrieval failed
  def get_gpg_key_from_1password
    logger.info('Retrieving GPG key from 1Password...')
    op_path = "op://#{@op_vault}/#{@op_gpg_key_path}"
    logger.info("Using 1Password path: #{op_path}")
    
    key_data = run_command(['op', 'read', op_path])

    if !key_data || key_data.empty?
      logger.error('Failed to retrieve GPG key from 1Password')
      logger.error("Make sure you have a secure note at the path: #{op_path}")
      return nil
    end

    key_data
  end

  # Extracts a key identifier from GPG key content
  #
  # Tries multiple patterns in order of preference:
  # 1. 40-character fingerprint
  # 2. 16-character short ID
  # 3. Email address
  #
  # @param gpg_key [String] The GPG key content
  # @return [String, nil] The extracted key identifier or nil if none found
  def extract_key_id(gpg_key)
    # If key ID is provided in config, use it
    return @gpg_key_id if @gpg_key_id && !@gpg_key_id.to_s.empty?
    
    patterns = [
      /[0-9A-F]{40}/,
      /[0-9A-F]{16}/,
      /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/
    ]

    patterns.each do |pattern|
      match = gpg_key.match(pattern)
      return match[0] if match
    end

    nil
  end

  # Checks if a GPG key is already imported in the keyring
  #
  # @param key_id [String] The key identifier to check
  # @return [Boolean] true if the key is already imported, false otherwise
  def key_already_imported?(key_id)
    return false if !key_id || key_id.to_s.empty?

    result = run_command(%w[gpg --list-secret-keys] + [key_id])
    !result.nil? && !result.empty?
  end

  # Imports a GPG key into the keyring
  #
  # @param gpg_key [String] The GPG key content to import
  # @return [String, nil] The import output or nil if import failed
  def import_gpg_key(gpg_key)
    logger.info('Importing GPG key...')
    result = run_command(%w[gpg --import], gpg_key)

    if !result || result.empty?
      logger.error('Failed to import GPG key')
      return nil
    end

    logger.info('GPG key imported successfully')
    result
  end

  # Extracts a key identifier from GPG import output
  #
  # @param import_output [String] The output from GPG key import
  # @return [String, nil] The extracted key identifier or nil if none found
  def extract_key_id_from_import(import_output)
    return nil if !import_output || import_output.empty?

    match = import_output.match(/key ([0-9A-F]{16}):/)
    match ? match[1] : nil
  end

  # Main execution flow for GPG key import
  #
  # This method:
  # 1. Signs in to 1Password
  # 2. Retrieves the GPG key from 1Password
  # 3. Attempts to extract a key identifier
  # 4. Checks if the key is already imported
  # 5. Imports the key if needed
  # 6. Extracts key ID from import output if not found earlier
  #
  # @return [void]
  def run
    unless signin_to_1password
      exit(1)
    end

    gpg_key = get_gpg_key_from_1password
    exit(1) if !gpg_key || gpg_key.empty?

    key_id = extract_key_id(gpg_key)
    if key_id && !key_id.to_s.empty?
      logger.info("Using key identifier: #{key_id}")
    else
      logger.info('No key identifier found')
    end

    if key_id && !key_id.to_s.empty? && key_already_imported?(key_id)
      logger.info('GPG key already imported, skipping import.')
      return
    end

    import_output = import_gpg_key(gpg_key)

    if (!key_id || key_id.to_s.empty?) && import_output && !import_output.empty?
      key_id = extract_key_id_from_import(import_output)
      logger.info("Extracted key ID from import: #{key_id}") if key_id && !key_id.to_s.empty?
    end
  end
end

# Run the script
ImportGpg.new.run if $PROGRAM_NAME == __FILE__
