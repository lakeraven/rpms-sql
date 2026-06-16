# frozen_string_literal: true

require "test_helper"
require "rpms_sql/client"

class RpmsSql::ClientTest < Minitest::Test
  def test_requires_host_user_and_password
    base = { host: "h", user: "u", password: "p" }
    assert_raises(ArgumentError) { RpmsSql::Client.new(**base.merge(host: "")) }
    assert_raises(ArgumentError) { RpmsSql::Client.new(**base.merge(user: "")) }
    assert_raises(ArgumentError) { RpmsSql::Client.new(**base.merge(password: "")) }
  end

  def test_defaults_namespace_and_port
    client = RpmsSql::Client.new(host: "iris.example.com", user: "u", password: "p")
    assert_equal "iris.example.com", client.host
    assert_equal RpmsSql::Client::DEFAULT_PORT, client.port
    assert_equal RpmsSql::Client::DEFAULT_NAMESPACE, client.namespace
  end

  def test_accepts_explicit_port_and_namespace
    client = RpmsSql::Client.new(
      host: "iris.example.com", port: 15432,
      namespace: "USER", user: "u", password: "p"
    )
    assert_equal 15432, client.port
    assert_equal "USER", client.namespace
  end
end
