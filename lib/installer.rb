#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'yaml'
require_relative 'bootkit_helpers'
require_relative 'import_gpg'

module BootKit
  # Installer handles the main installation process for BootKit
  class Installer
    include BootKit::Helpers
    
    # Initializes the installer with configuration from bootkit.yml
    #
    # @return [void]
    def initialize
      @config = load_config
    end
    
    # Load configuration from YAML file
    #
    # Checks if bootkit.yml exists and loads it
    # Exits with error if the file doesn't exist
    #
    # @return [Hash] Configuration values
    def load_config
      config_path = File.join(File.dirname(__FILE__), '..', 'bootkit.yml')
      example_path = File.join(File.dirname(__FILE__), '..', 'bootkit.example.yml')
      
      unless File.exist?(config_path)
        logger.error("Configuration file not found: #{config_path}")
        logger.error("Please create your configuration file before running the installer:")
        logger.error("1. Copy the example: cp #{example_path} #{config_path}")
        logger.error("2. Edit the file with your personal settings")
        exit(1)
      end
      
      begin
        YAML.load_file(config_path) || {}
      rescue => e
        logger.error("Error loading configuration: #{e.message}")
        {}
      end
    end

    # Runs the complete installation process for BootKit
    #
    # Executes all installation steps in sequence:
    # - Verifies macOS environment
    # - Installs Homebrew package manager
    # - Installs 1Password CLI
    # - Installs packages from Brewfile
    # - Makes scripts executable
    # - Imports GPG keys from 1Password
    # - Sets up dotdrop for dotfile management
    # - Sets up Zgenom for Zsh plugin management
    #
    # @return [void]
    def run
      check_macos
      install_homebrew
      install_1password_cli
      install_packages
      make_scripts_executable
      import_gpg_key
      setup_dotdrop
      setup_zgenom

      logger.info("Installation completed successfully!")
    end

    # Verifies that the script is running on macOS
    #
    # Exits with error code 1 if not running on macOS
    #
    # @return [void]
    def check_macos
      unless RUBY_PLATFORM.include?('darwin')
        logger.error("This script is intended to run on macOS only.")
        exit(1)
      end
    end

    # Installs Homebrew package manager if not already installed
    #
    # Detects Apple Silicon vs Intel architecture and configures
    # the appropriate Homebrew environment
    #
    # @return [void]
    def install_homebrew
      if command_exists?('brew')
        logger.info("Homebrew is already installed.")
        return
      end

      logger.info("Installing Homebrew...")
      install_cmd = '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'

      unless system(install_cmd)
        logger.error("Failed to install Homebrew.")
        exit(1)
      end

      if `uname -m`.strip == 'arm64'
        system('eval "$(/opt/homebrew/bin/brew shellenv)"')
      else
        system('eval "$(/usr/local/bin/brew shellenv)"')
      end
    end

    # Installs 1Password CLI if not already installed
    #
    # Uses Homebrew to install the 1Password CLI tool
    #
    # @return [void]
    def install_1password_cli
      if command_exists?('op')
        logger.info("1Password CLI is already installed.")
        return
      end

      logger.info("1Password CLI (op) not found, installing...")
      unless system('brew install --cask 1password-cli')
        logger.error("Failed to install 1Password CLI.")
        exit(1)
      end
    end

    # Updates Homebrew and installs packages from Brewfile
    #
    # Updates Homebrew repositories and installs all packages
    # defined in the project's Brewfile
    #
    # @return [void]
    def install_packages
      logger.info("Updating Homebrew and installing packages...")

      unless system('brew update')
        logger.warn("Failed to update Homebrew, continuing anyway...")
      end

      unless system('brew bundle')
        logger.error("Failed to install packages from Brewfile.")
        exit(1)
      end
    end

    # Makes all scripts in the bin directory executable
    #
    # Sets the executable permission (0755) on all files in the bin directory
    #
    # @return [void]
    def make_scripts_executable
      logger.info("Making scripts executable...")
      bin_dir = File.join(File.dirname(__FILE__), '..', 'bin')
      Dir.glob(File.join(bin_dir, '*')).each do |file|
        File.chmod(0755, file) if File.file?(file)
      end
    end

    # Imports GPG keys from 1Password into the local GPG keyring
    #
    # Creates a new ImportGpg instance and runs the import process
    # to retrieve and import GPG keys stored in 1Password
    #
    # @return [void]
    def import_gpg_key
      logger.info("Setting up GPG key from 1Password...")
      BootKit::ImportGpg.new.run
    end

    # Sets up dotdrop for dotfile management
    #
    # Extracts the GPG key ID from the keyring and uses it to
    # configure dotdrop for dotfile installation with the specified profile
    #
    # @return [void]
    def setup_dotdrop
      logger.info("Setting up dotdrop for dotfile management...")
      
      # Extract GPG key ID for dotdrop
      logger.info("Extracting GPG key ID for dotdrop...")
      gpg_key_id = run_command(['gpg', '--list-secret-keys', '--with-colons']).
                   to_s.
                   lines.
                   grep(/^sec/).
                   first&.
                   split(':')&.[](4)
      
      if gpg_key_id.nil? || gpg_key_id.empty?
        logger.warn("Failed to extract GPG key ID. Dotfile encryption/decryption may fail.")
      else
        logger.info("Using GPG key ID: #{gpg_key_id}")
        ENV['GPG_KEY_ID'] = gpg_key_id
      end
      
      # Install dotfiles with Dotdrop
      logger.info("Installing dotfiles with Dotdrop...")
      profile = @config.dig('dotdrop', 'profile') || 'PUB-MAC-BRASA'
      
      unless system("dotdrop install -p #{profile}")
        logger.warn("Dotdrop installation encountered issues. Please check the output above.")
      end
    end
    
    # Sets up Zgenom for Zsh plugin management
    #
    # Clones the Zgenom repository if it doesn't exist
    # to enable Zsh plugin management
    #
    # @return [void]
    def setup_zgenom
      logger.info("Setting up Zgenom for Zsh plugin management...")
      zgenom_dir = File.join(ENV['HOME'], '.zgenom')
      
      if Dir.exist?(zgenom_dir)
        logger.info("Zgenom is already installed.")
        return
      end
      
      logger.info("Installing Zgenom...")
      unless system("git clone https://github.com/jandamm/zgenom.git #{zgenom_dir}")
        logger.warn("Failed to install Zgenom. Zsh plugin management may not work correctly.")
      end
    end

    # Checks if a command exists in the system PATH
    #
    # @param command [String] The command to check
    # @return [Boolean] true if the command exists, false otherwise
    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
  end
end
