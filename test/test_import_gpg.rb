#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../lib/import_gpg'

# Test class for ImportGpg
class TestImportGpg < Minitest::Test
  def setup
    @import_gpg = BootKit::ImportGpg.new
  end

  def test_extract_key_id
    # Test with fingerprint
    gpg_key_with_fingerprint = "Comment: GPG key\nABCD1234ABCD1234ABCD1234ABCD1234ABCD1234"
    assert_equal 'ABCD1234ABCD1234ABCD1234ABCD1234ABCD1234', @import_gpg.extract_key_id(gpg_key_with_fingerprint)

    # Test with short ID
    gpg_key_with_short_id = "Comment: GPG key\nABCD1234ABCD1234"
    assert_equal 'ABCD1234ABCD1234', @import_gpg.extract_key_id(gpg_key_with_short_id)

    # Test with email
    gpg_key_with_email = "Comment: GPG key\nuser@example.com"
    assert_equal 'user@example.com', @import_gpg.extract_key_id(gpg_key_with_email)

    # Test with no identifiable information
    gpg_key_without_id = "Comment: GPG key\nNo identifiable information"
    assert_nil @import_gpg.extract_key_id(gpg_key_without_id)
  end

  def test_extract_key_id_from_import
    # Test with valid import output
    import_output = 'gpg: key ABCD1234ABCD1234: public key imported'
    assert_equal 'ABCD1234ABCD1234', @import_gpg.extract_key_id_from_import(import_output)

    # Test with invalid import output
    invalid_output = 'gpg: no valid OpenPGP data found'
    assert_nil @import_gpg.extract_key_id_from_import(invalid_output)

    # Test with empty output
    assert_nil @import_gpg.extract_key_id_from_import('')
    assert_nil @import_gpg.extract_key_id_from_import(nil)
  end
end
