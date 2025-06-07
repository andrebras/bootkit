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
    # @return [Boolean] true if setup was successful
    def setup
      logger.info("Setting up GPG key from 1Password...")
      
      # Check if GPG is installed
      unless command_exists?('gpg')
        logger.error("GPG is not installed. Please install it first.")
        return false
      end
      
      # Check if 1Password CLI is installed
      unless command_exists?('op')
        logger.error("1Password CLI is not installed. Please install it first.")
        return false
      end
      
      # Sign in to 1Password if needed
      sign_in_to_1password
      
      # Get GPG key from 1Password
      gpg_key = get_gpg_key_from_1password
      return false unless gpg_key
      
      # Import GPG key
      import_gpg_key(gpg_key)
    end
    
    # Gets the GPG key ID for the imported key
    #
    # @return [String, nil] The GPG key ID or nil if not found
    def get_key_id
      result = run_command(['gpg', '--list-secret-keys', '--with-colons'])
      return nil unless result[:success]
      
      key_id_line = result[:stdout].to_s.lines.grep(/^sec/).first
      return nil unless key_id_line
      
      key_id = key_id_line.split(':')[4]
      key_id
    end
    
    private
    
    # Sign in to 1Password if not already signed in
    #
    # @return [Boolean] true if signed in successfully
    def sign_in_to_1password
      logger.info("Checking 1Password CLI session...")
      
      # Check if already signed in
      result = run_command('op account list')
      if result[:success]
        logger.info("Already signed in to 1Password")
        return true
      end
      
      logger.info("Signing in to 1Password...")
      logger.info("Please follow the prompts to sign in to your 1Password account")
      
      # Run the signin command interactively
      system('op signin')
    end
    
    # Get GPG key from 1Password
    #
    # @return [String, nil] The GPG key content or nil if retrieval failed
    def get_gpg_key_from_1password
      logger.info("Retrieving GPG key from 1Password...")
      
      # Get configuration
      vault = @config_manager.get('onepassword', 'vault', default: 'Dotfiles')
      gpg_key_path = @config_manager.get('onepassword', 'gpg_key_path', default: 'GPG Key/notes')
      
      # Split the path into item and field
      item_path, field = gpg_key_path.split('/')
      field ||= 'notes'
      
      logger.info("Looking for GPG key in vault: #{vault}, item: #{item_path}, field: #{field}")
      
      # Try to get the entire item and extract the notes field
      result = run_command(['op', 'item', 'get', item_path, '--vault', vault, '--format', 'json'])
      
      unless result[:success]
        logger.error("Failed to retrieve item from 1Password")
        logger.error(result[:stderr])
        return nil
      end
      
      begin
        item_data = JSON.parse(result[:stdout])
        
        # Try to find the notes field in the item data
        if item_data['fields']
          notes_field = item_data['fields'].find { |f| 
            f['id'] == 'notesPlain' || 
            f['purpose'] == 'NOTES' || 
            f['label'] == 'notesPlain'
          }
          
          if notes_field && notes_field['value']
            logger.info("Successfully retrieved GPG key from 1Password")
            return notes_field['value']
          end
        end
        
        logger.error("Could not find notes field in the 1Password item")
        nil
      rescue => e
        logger.error("Failed to parse JSON response: #{e.message}")
        nil
      end
    end
    
    # Import GPG key into the local keyring
    #
    # @param gpg_key [String] The GPG key content
    # @return [Boolean] true if import was successful
    def import_gpg_key(gpg_key)
      logger.info("Importing GPG key...")
      
      # Check if the key is already imported
      key_id = extract_key_id(gpg_key)
      if key_id && key_already_imported?(key_id)
        logger.info("GPG key is already imported")
        return true
      end
      
      # Import the key
      result = run_command(['gpg', '--import'], input: gpg_key)
      
      unless result[:success]
        logger.error("Failed to import GPG key")
        logger.error(result[:stderr])
        return false
      end
      
      if key_imported?(result[:stderr])
        logger.info("Successfully imported GPG key")
        return true
      else
        logger.error("Failed to import GPG key: #{result[:stderr]}")
        return false
      end
    end
    
    # Extract key ID from GPG key content
    #
    # @param gpg_key [String] The GPG key content
    # @return [String, nil] The key ID or nil if not found
    def extract_key_id(gpg_key)
      # Try to extract key ID from the key content
      match = gpg_key.match(/-----BEGIN PGP PRIVATE KEY BLOCK-----(.*?)-----END PGP PRIVATE KEY BLOCK-----/m)
      return nil unless match
      
      # Import key to a temporary keyring to get the ID
      tempdir = Dir.mktmpdir
      begin
        # Create a temporary GNUPGHOME
        env = { 'GNUPGHOME' => tempdir }
        
        # Import the key to the temporary keyring
        result = run_command(['gpg', '--import'], env: env, input: gpg_key)
        return nil unless result[:success]
        
        # List the keys in the temporary keyring
        result = run_command(['gpg', '--list-secret-keys', '--with-colons'], env: env)
        return nil unless result[:success]
        
        # Extract the key ID
        key_id_line = result[:stdout].to_s.lines.grep(/^sec/).first
        return nil unless key_id_line
        
        key_id = key_id_line.split(':')[4]
        return key_id
      ensure
        FileUtils.remove_entry_secure(tempdir)
      end
    end
    
    # Check if a key is already imported
    #
    # @param key_id [String] The key ID to check
    # @return [Boolean] true if the key is already imported
    def key_already_imported?(key_id)
      result = run_command(['gpg', '--list-secret-keys', key_id])
      result[:success]
    end
    
    # Check if a key was imported based on GPG output
    #
    # @param output [String] The GPG command output
    # @return [Boolean] true if the key was imported
    def key_imported?(output)
      output.include?('secret key imported') || 
      output.include?('secret keys read') || 
      output.include?('not changed')
    end
  end
end
