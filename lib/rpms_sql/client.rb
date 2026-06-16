# frozen_string_literal: true

require "pg"
require_relative "version"
require_relative "sql_safety"

module RpmsSql
  # Talks SQL to InterSystems IRIS over PostgreSQL wire protocol.
  #
  # Requires iris-pgwire installed on the IRIS server
  # (https://github.com/intersystems-community/iris-pgwire). With pgwire
  # running, IRIS listens on a PostgreSQL-protocol port (default 5432) and
  # the `pg` gem connects like to any Postgres database. The IRIS namespace
  # becomes the PG database name; SCRAM-SHA-256 handles auth.
  #
  # Never bake in InterSystems install defaults (`_SYSTEM:SYS`); require
  # explicit configuration of a Lakeraven-provisioned IRIS user.
  #
  # `query(sql, params)` is the bottom primitive. For higher-level ergonomics
  # (avoiding raw SQL in engine code), expect an `rpms-sql-activerecord`
  # companion gem or use Sequel directly:
  #
  #   db = Sequel.connect("postgres://user:pass@host:5432/RPMS")
  #   db[:patients].where(dob: ...).first
  #
  # iris-pgwire speaks standard PG protocol so both AR and Sequel work
  # without rpms-sql in the loop, when that fits.
  class Client
    class QueryError < StandardError; end
    class ReadOnlyViolation < QueryError; end

    DEFAULT_PORT = 5432
    DEFAULT_NAMESPACE = "RPMS"

    attr_reader :host, :port, :namespace

    def initialize(host:, user:, password:, port: DEFAULT_PORT,
                   namespace: DEFAULT_NAMESPACE, connect_timeout: 5)
      raise ArgumentError, "host required" if host.to_s.empty?
      raise ArgumentError, "user required" if user.to_s.empty?
      raise ArgumentError, "password required" if password.to_s.empty?

      @host = host
      @port = port
      @namespace = namespace
      @user = user
      @password = password
      @connect_timeout = connect_timeout
    end

    def query(sql, params = [])
      SqlSafety.assert_read_only!(sql)

      result = params.empty? ? connection.exec(sql) : connection.exec_params(sql, params)
      rows = result.to_a
      result.clear
      rows
    rescue PG::Error => e
      raise QueryError, e.message
    end

    def close
      @connection&.close
      @connection = nil
    end

    private

    def connection
      @connection ||= PG::Connection.new(
        host: @host, port: @port, dbname: @namespace,
        user: @user, password: @password,
        connect_timeout: @connect_timeout
      )
    end
  end
end
