# frozen_string_literal: true

require_relative "client"
require_relative "sql_safety"

module RpmsSql
  # Test double for Client. Seed responses by exact SQL match via
  # `seed(sql, rows)` or seed an error via `seed_error(sql, message)`.
  # Received queries are recorded on `received_calls` for assertions.
  class MockClient
    attr_reader :received_calls

    def initialize
      @rows = {}
      @errors = {}
      @received_calls = []
    end

    def seed(sql, rows)
      @rows[sql] = rows
    end

    def seed_error(sql, message)
      @errors[sql] = message
    end

    def query(sql, params = [])
      SqlSafety.assert_read_only!(sql)

      @received_calls << { sql: sql, params: params }
      raise Client::QueryError, @errors[sql] if @errors.key?(sql)

      @rows.fetch(sql, [])
    end

    def close
      nil
    end
  end
end
