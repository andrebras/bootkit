#!/usr/bin/env ruby
# frozen_string_literal: true

require 'yaml'
require_relative 'bootkit_helpers'

module BootKit
  # ConfigManager handles loading and accessing configuration for BootKit
  class ConfigManager
    include BootKit::Helpers

    attr_reader :config

    # Initialize the ConfigManager
    #
    # @return [void]
    def initialize(config_path = nil)
      config_path ||= File.join(File.dirname(__FILE__), '..', 'bootkit.yml')
      @config = load_config(config_path)
    end

    # Load configuration from YAML file
    #
    # Checks if bootkit.yml exists and loads it
    # Exits with error if the file doesn't exist
    #
    # @return [Hash] Configuration values
    def load_config(config_path)
      unless File.exist?(config_path)
        logger.error("Configuration file not found: #{config_path}")
        logger.error('Please create your configuration file before running the installer:')
        logger.error('1. Copy the example to bootkit.yml')
        logger.error('2. Edit the file with your personal settings')
        exit(1)
      end

      YAML.load_file(config_path) || {}
    rescue StandardError => e
      logger.error("Error loading configuration: #{e.message}")
      {}
    end

    # Get a configuration value using a path of keys
    #
    # @param keys [Array<String, Symbol>] The path of keys to the desired value
    # @param default [Object] The default value to return if the key doesn't exist
    # @return [Object] The configuration value or default if not found
    def get(*keys, default: nil)
      result = @config

      keys.each do |key|
        key = key.to_s
        return default unless result.is_a?(Hash) && result.key?(key)

        result = result[key]
      end

      result.nil? ? default : result
    end
  end
end
