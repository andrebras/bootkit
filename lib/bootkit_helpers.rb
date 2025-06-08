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
    # @param cmd [Array<String>, String] The command to execute as an array of strings
    #                                    or a single string
    # @param options [Hash] Options for command execution
    # @option options [Hash] :env Environment variables to set for the command
    # @option options [String] :dir Working directory for the command
    # @option options [String] :input Input data to pass to the command
    # @option options [Integer] :timeout Timeout in seconds (not implemented yet)
    # @return [Hash] Result hash with :stdout, :stderr, :status, and :success keys
    def run_command(cmd, options = {})
      # Convert string command to array if needed
      cmd = cmd.split if cmd.is_a?(String)

      # Extract options and prepare execution
      env = options[:env] || {}
      execution_options = prepare_execution_options(options)

      log_command_execution(cmd, env, options[:dir])

      # Execute command
      stdout_str, stderr_str, status = Open3.capture3(env, *cmd, execution_options)

      # Prepare and return result
      create_result_hash(stdout_str, stderr_str, status)
    end

    # Prepare execution options for Open3.capture3
    #
    # @param options [Hash] Options for command execution
    # @return [Hash] Execution options for Open3.capture3
    def prepare_execution_options(options)
      execution_options = {}
      execution_options[:stdin_data] = options[:input] if options[:input]
      execution_options[:chdir] = options[:dir] if options[:dir]
      execution_options
    end

    # Log command execution details
    #
    # @param cmd [Array<String>] The command to execute
    # @param env [Hash] Environment variables
    # @param dir [String, nil] Working directory
    # @return [void]
    def log_command_execution(cmd, env, dir)
      logger.debug("Running command: #{cmd.join(' ')}")
      logger.debug("With environment: #{env.inspect}") unless env.empty?
      logger.debug("In directory: #{dir}") if dir
    end

    # Create result hash from command execution
    #
    # @param stdout_str [String] Standard output
    # @param stderr_str [String] Standard error
    # @param status [Process::Status] Process status
    # @return [Hash] Result hash
    def create_result_hash(stdout_str, stderr_str, status)
      result = {
        stdout: stdout_str,
        stderr: stderr_str,
        status: status.exitstatus,
        success: status.success?
      }

      log_command_result(status, stderr_str)
      result
    end

    # Log the result of a command execution
    #
    # @param status [Process::Status] Process status
    # @param stderr_str [String] Standard error output
    # @return [void]
    def log_command_result(status, stderr_str)
      if status.success?
        logger.debug('Command succeeded')
      else
        logger.warn("Command failed with status #{status.exitstatus}")
        logger.debug("STDERR: #{stderr_str}")
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
    # @return [String, nil] Package name if the package is installed or installation succeeded,
    #                       nil otherwise
    def install_brew_package(package, options = '')
      if system("brew list #{package} &>/dev/null")
        logger.info("Package '#{package}' is already installed.")
        return package
      end

      logger.info("Installing package '#{package}'...")
      perform_brew_install(package, options)
    end

    # Perform the actual Homebrew package installation
    #
    # @param package [String] The package to install
    # @param options [String] Additional options for brew install
    # @return [String, nil] Package name if installation succeeded, nil otherwise
    def perform_brew_install(package, options)
      cmd = "brew install #{options} #{package}"

      unless system(cmd)
        logger.error("Failed to install package '#{package}'.")
        return nil
      end

      package
    end

    # Ensures a directory exists, creating it if necessary
    #
    # @param dir [String] The directory path
    # @return [Array, false] Array containing the directory path if it exists or was created, nil otherwise
    def ensure_directory(dir)
      return [dir] if Dir.exist?(dir)

      logger.info("Creating directory: #{dir}")
      FileUtils.mkdir_p(dir)
    rescue StandardError => e
      logger.error("Failed to create directory #{dir}: #{e.message}")
      nil
    end
  end
end
