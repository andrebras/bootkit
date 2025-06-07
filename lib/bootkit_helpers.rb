#!/usr/bin/env ruby
# frozen_string_literal: true

require 'open3'
require 'logger'
require 'fileutils'

module BootKit
  # Helper module providing common utilities for BootKit components
  #
  # This module contains shared functionality like logging, command execution,
  # and filesystem operations used across the BootKit installer.
  module Helpers
    # Also provide module methods for backward compatibility
    extend self
    
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
    # @param cmd [Array<String>, String] The command to execute as an array of strings or a single string
    # @param options [Hash] Options for command execution
    # @option options [Hash] :env Environment variables to set for the command
    # @option options [String] :dir Working directory for the command
    # @option options [String] :input Input data to pass to the command
    # @option options [Integer] :timeout Timeout in seconds (not implemented yet)
    # @return [Hash] Result hash with :stdout, :stderr, :status, and :success keys
    def run_command(cmd, options = {})
      # Convert string command to array if needed
      cmd = cmd.split(' ') if cmd.is_a?(String)
      
      # Extract options
      env = options[:env] || {}
      dir = options[:dir]
      input_data = options[:input]
      
      logger.debug("Running command: #{cmd.join(' ')}")
      if !env.empty?
        logger.debug("With environment: #{env.inspect}")
      end
      if dir
        logger.debug("In directory: #{dir}")
      end
      
      # Prepare execution options
      execution_options = {}
      execution_options[:stdin_data] = input_data if input_data
      execution_options[:chdir] = dir if dir
      
      # Execute command
      stdout_str, stderr_str, status = Open3.capture3(env, *cmd, execution_options)
      
      # Prepare result
      result = {
        stdout: stdout_str,
        stderr: stderr_str,
        status: status.exitstatus,
        success: status.success?
      }
      
      if status.success?
        logger.debug("Command succeeded")
      else
        logger.warn("Command failed with status #{status.exitstatus}")
        logger.debug("STDERR: #{stderr_str}")
      end
      
      result
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
        logger.info("Package '#{package}' is already installed.")
        return true
      end
      
      logger.info("Installing package '#{package}'...")
      cmd = "brew install #{options} #{package}"
      
      unless system(cmd)
        logger.error("Failed to install package '#{package}'.")
        return false
      end
      
      true
    end
    
    # Ensures a directory exists, creating it if necessary
    #
    # @param dir [String] The directory path
    # @return [Boolean] true if the directory exists or was created
    def ensure_directory(dir)
      return true if Dir.exist?(dir)
      
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
end
