#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../test_helper'
require 'gpg_manager'
require 'stringio'

class TestGpgManager < Minitest::Test
  include TestHelpers

  def setup
    @temp_dir, @config_file = create_temp_config_from_fixture('bootkit.test.yml')
    @gpg_manager = BootKit::GpgManager.new(BootKit::ConfigManager.new(@config_file))
    @original_key_id = ENV.fetch('GPG_KEY_ID', nil)
  end

  def teardown
    ENV['GPG_KEY_ID'] = @original_key_id
    FileUtils.remove_entry @temp_dir if @temp_dir && File.directory?(@temp_dir)
  end

  def test_extract_key_id_from_output
    output = "sec:u:4096:1:ABCD1234ABCD1234:1700000000:::u:::scESC:::+:::23::0:\n"

    assert_equal 'ABCD1234ABCD1234', @gpg_manager.extract_key_id_from_output(output)
  end

  def test_extract_key_id_from_output_without_secret_key
    assert_nil @gpg_manager.extract_key_id_from_output("pub:u:4096:1:ABCD1234ABCD1234\n")
    assert_nil @gpg_manager.extract_key_id_from_output(nil)
  end

  def test_key_id_from_content_without_private_key
    assert_nil @gpg_manager.key_id_from_content('not a key')
  end

  def test_key_id_prefers_environment
    ENV['GPG_KEY_ID'] = 'FROMENV1'

    assert_equal 'FROMENV1', @gpg_manager.key_id
  end

  def test_key_imported
    assert @gpg_manager.key_imported?('gpg: secret key imported')
    assert @gpg_manager.key_imported?('gpg:       secret keys imported: 1')
    refute @gpg_manager.key_imported?('gpg: no valid OpenPGP data found')
  end

  def test_find_notes_field
    item = { 'fields' => [{ 'id' => 'username' }, { 'id' => 'notesPlain', 'value' => 'key' }] }

    assert_equal 'key', @gpg_manager.find_notes_field(item)['value']
    assert_nil @gpg_manager.find_notes_field({})
  end

  def test_gpg_key_from_item_without_notes
    @gpg_manager.logger.level = Logger::FATAL

    assert_nil @gpg_manager.gpg_key_from_item({ 'fields' => [] })
  end

  def test_failed_import_does_not_log_key_content
    output = StringIO.new
    @gpg_manager.instance_variable_set(:@logger, Logger.new(output, level: Logger::DEBUG))
    @gpg_manager.define_singleton_method(:key_id_from_content) { |_key| 'ABCD1234' }
    @gpg_manager.define_singleton_method(:key_already_imported?) { |_id| false }
    @gpg_manager.define_singleton_method(:perform_key_import) { |_key| { success: false, stderr: '' } }

    assert_nil @gpg_manager.import_gpg_key('SECRET-KEY-MATERIAL')
    refute_includes output.string, 'SECRET-KEY-MATERIAL'
  end

  def test_dependencies_available_without_gpg
    @gpg_manager.logger.level = Logger::FATAL
    @gpg_manager.define_singleton_method(:command_exists?) { |cmd| cmd != 'gpg' }

    refute @gpg_manager.dependencies_available?
  end
end
