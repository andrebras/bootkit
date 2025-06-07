#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'logger'
require 'fileutils'

# BootKit Helper Library
#
# This library provides common helper functions for BootKit scripts.
# It includes utilities for running commands, logging, and other shared functionality.
#
# Usage:
#   # To use as module methods:
#   include BootKit::Helpers
#
#   # To use as singleton methods:
#   extend BootKit::Helpers
module BootKit
  module Helpers
    # Creates a logger instance
    #
    # @param level [Symbol, String] The log level (debug, info, warn, error)
    # @return [Logger] A configured logger instance
    def logger(level = nil)
      @logger ||= Logger.new($stdout).tap do |l|
        l.formatter = proc { |severity, _datetime, _progname, msg| "#{severity}: #{msg}\n" }
        l.level = Logger::INFO
      end
      
      if level
        level = level.to_s.upcase
        @logger.level = Logger.const_get(level) if Logger.constants.include?(level.to_sym)
      end
      
      @logger
    end
    
    # Executes a shell command and handles errors
    #
    # @param cmd [Array<String>] The command to execute as an array of strings
    # @param input_data [String, nil] Optional input data to pass to the command
    # @return [String, nil] The command output or nil if the command failed
    def run_command(cmd, input_data = nil)
      logger.debug("Running command: #{cmd.join(' ')}")
      
      stdout_str, stderr_str, status = Open3.capture3(*cmd, stdin_data: input_data)
      
      if status.success?
        logger.debug("Command succeeded")
        stdout_str
      else
        logger.error("Command failed: #{stderr_str}")
        nil
      end
    end
    
    # Checks if a command is available in the system
    #
    # @param command [String] The command to check
    # @return [Boolean] true if the command is available, false otherwise
    def command_exists?(command)
      system("which #{command} > /dev/null 2>&1")
    end
    
    # Installs a Homebrew package if not already installed
    #
    # @param package [String] The package to install
    # @param options [String] Additional options for brew install
    # @return [Boolean] true if the package is installed or installation succeeded
    def ensure_brew_package(package, options = '')
      if system("brew list #{package} &>/dev/null")
        logger.info("#{package} is already installed")
        return true
      end
      
      logger.info("Installing #{package}...")
      system("brew install #{options} #{package}")
    end
    
    # Ensures a directory exists, creating it if necessary
    #
    # @param dir [String] The directory path
    # @return [Boolean] true if the directory exists or was created
    def ensure_directory(dir)
      if Dir.exist?(dir)
        logger.debug("Directory exists: #{dir}")
        return true
      end
      
      logger.info("Creating directory: #{dir}")
      begin
        FileUtils.mkdir_p(dir)
        true
      rescue => e
        logger.error("Failed to create directory #{dir}: #{e.message}")
        false
      end
    end
  end

  # Also provide module methods for backward compatibility
  extend Helpers
end
