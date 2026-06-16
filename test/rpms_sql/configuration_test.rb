# frozen_string_literal: true

require "test_helper"

class RpmsSql::ConfigurationTest < Minitest::Test
  def teardown
    RpmsSql.reset!
  end

  def test_client_raises_when_not_configured
    assert_raises(RpmsSql::NotConfiguredError) { RpmsSql.client }
  end

  def test_configure_yields_configuration_object
    yielded = nil
    RpmsSql.configure { |c| yielded = c }
    assert_instance_of RpmsSql::Configuration, yielded
  end

  def test_mock_provisions_client
    mock = RpmsSql.mock!
    assert_instance_of RpmsSql::MockClient, mock
    assert_equal mock, RpmsSql.client
  end

  def test_mock_yields_for_seeding
    yielded = nil
    RpmsSql.mock! { |m| yielded = m }
    assert_equal RpmsSql.client, yielded
  end

  def test_reset_clears_configuration
    RpmsSql.mock!
    RpmsSql.reset!
    assert_raises(RpmsSql::NotConfiguredError) { RpmsSql.client }
  end
end
