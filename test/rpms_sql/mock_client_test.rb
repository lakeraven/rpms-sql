# frozen_string_literal: true

require "test_helper"

class RpmsSql::MockClientTest < Minitest::Test
  def setup
    @mock = RpmsSql.mock!
  end

  def teardown
    RpmsSql.reset!
  end

  def test_query_returns_seeded_rows
    @mock.seed("SELECT TOP 1 Number FROM %FileMan.File",
               [ { "Number" => "2", "Name" => "VA PATIENT" } ])

    rows = @mock.query("SELECT TOP 1 Number FROM %FileMan.File")
    assert_equal [ { "Number" => "2", "Name" => "VA PATIENT" } ], rows
  end

  def test_query_returns_empty_for_unseeded_sql
    assert_equal [], @mock.query("SELECT 1")
  end

  def test_query_records_received_calls
    @mock.query("SELECT 1 AS N")
    @mock.query("SELECT 2 AS N", [ 42 ])

    assert_equal 2, @mock.received_calls.size
    assert_equal "SELECT 1 AS N", @mock.received_calls[0][:sql]
    assert_equal [], @mock.received_calls[0][:params]
    assert_equal "SELECT 2 AS N", @mock.received_calls[1][:sql]
    assert_equal [ 42 ], @mock.received_calls[1][:params]
  end

  def test_query_raises_when_seeded_with_error
    @mock.seed_error("SELECT TOP 3 IEN FROM BMW.PATIENT", "Class does not exist")

    err = assert_raises(RpmsSql::Client::QueryError) do
      @mock.query("SELECT TOP 3 IEN FROM BMW.PATIENT")
    end
    assert_match(/Class does not exist/, err.message)
  end

  def test_close_is_noop
    assert_nil @mock.close
  end

  def test_query_raises_read_only_violation_on_write_sql
    assert_raises(RpmsSql::Client::ReadOnlyViolation) do
      @mock.query("INSERT INTO BMW.PATIENT (NAME) VALUES ('x')")
    end
  end
end
