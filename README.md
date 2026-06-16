# rpms-sql

Ruby client for IRIS-projected RPMS data via the PostgreSQL wire protocol. Companion to [rpms-rpc](https://github.com/lakeraven/rpms-rpc).

`rpms-rpc` talks XWB RPC to the broker. `rpms-sql` talks SQL to InterSystems IRIS over the PostgreSQL wire protocol (via [iris-pgwire](https://github.com/intersystems-community/iris-pgwire)) for high-throughput access to FileMan-projected tables — the same architectural path BPRM v4 uses.

## Status

Bootstrap. Foundation only — `Client` (pg-backed) + `MockClient` for tests. Live integration verification is pending iris-pgwire install on staging RPMS (tracked at [rpms-rpc#134](https://github.com/lakeraven/rpms-rpc/issues/134)).

## Installation

```ruby
# Gemfile
gem "rpms-sql"
```

## Usage

### Configuring a real client

```ruby
RpmsSql.configure do |c|
  c.client = RpmsSql::Client.new(
    host: "iris.example.com",
    port: 5432,                # iris-pgwire listener
    namespace: "RPMS",          # IRIS namespace == PG dbname
    user: ENV.fetch("RPMS_SQL_USER"),
    password: ENV.fetch("RPMS_SQL_PASSWORD")
  )
end

rows = RpmsSql.client.query("SELECT TOP 5 Number, Name FROM %FileMan.File")
```

### Configuring a mock client (tests)

```ruby
RpmsSql.mock! do |m|
  m.seed("SELECT Number FROM %FileMan.File WHERE Number = 2",
         [ { "Number" => "2", "Name" => "VA PATIENT" } ])
end

RpmsSql.client.query("SELECT Number FROM %FileMan.File WHERE Number = 2")
# => [ { "Number" => "2", "Name" => "VA PATIENT" } ]
```

## Avoiding raw SQL

`Client#query(sql)` is the bottom primitive. Engine code should generally not write raw SQL strings inline — prefer a query-builder layer:

- **Sequel** works out of the box against iris-pgwire (no rpms-sql wrapping required):
  ```ruby
  db = Sequel.connect("postgres://user:pass@host:5432/RPMS")
  db[:patients].where(dob: ..).first
  ```
- **ActiveRecord** companion (`rpms-sql-activerecord`) is planned once iris-pgwire is verified end-to-end against AR introspection and connection-pool semantics.

Raw `query` is appropriate for: schema introspection, one-off ops, migration-style scripts, and inside builder/adapter implementations.

## Why a separate gem from rpms-rpc

`rpms-rpc` is M/RPC broker access via XWB protocol. SQL-via-pgwire is a different protocol, different auth, different connection model, different performance profile, and applies to a different set of access patterns. Keeping the gems separate avoids dragging a `pg` dependency onto consumers who only need broker access (and vice versa).

## License

MIT
