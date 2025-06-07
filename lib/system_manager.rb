#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative 'bootkit_helpers'

module BootKit
  # SystemManager handles system compatibility checks and environment setup
  class SystemManager
    include BootKit::Helpers
    
    # Initializes the system manager
    #
    # @return [void]
    def initialize
      # No initialization needed currently
    end
    
    # Sets up the system by verifying compatibility requirements
    #
    # Currently checks that the system is running macOS
    # Exits with error code 1 if not running on macOS
    #
    # @return [void]
    def setup
      verify_macos
    end
    
    private
    
    # Verifies that the script is running on macOS
    #
    # @return [void]
    # @raise [SystemExit] if not running on macOS
    def verify_macos
      unless RUBY_PLATFORM.include?('darwin')
        logger.error("This script is intended to run on macOS only.")
        exit(1)
      end
      
      logger.info("Verified macOS environment.")
    end
  end
end
