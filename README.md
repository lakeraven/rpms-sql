# rpms-sql

Ruby client for IRIS-projected RPMS data via the PostgreSQL wire protocol. Companion to [rpms-rpc](https://github.com/lakeraven/rpms-rpc).

`rpms-rpc` talks XWB RPC to the broker. `rpms-sql` talks SQL to InterSystems IRIS over the PostgreSQL wire protocol (via [iris-pgwire](https://github.com/intersystems-community/iris-pgwire)) for high-throughput access to FileMan-projected tables — the same architectural path BPRM v4 uses.

## Status

Bootstrap. Foundation only — `Client` (pg-backed) + `MockClient` for tests. Live integration verification is pending iris-pgwire install on staging RPMS (tracked at [rpms-rpc#134](https://github.com/lakeraven/rpms-rpc/issues/134)).

## What rpms-sql does NOT do

**rpms-sql is read-only. Forever.** Writes go through [rpms-rpc](https://github.com/lakeraven/rpms-rpc) so they hit the broker → M routines → FileMan APIs and trigger the full FileMan business-logic stack. The `Client` and `MockClient` enforce this at the gem level (`SqlSafety.assert_read_only!` raises `Client::ReadOnlyViolation` on any non-read SQL); the IRIS user the gem connects as should also have SELECT-only grants at the database level as defense in depth.

The reason: writes via SQL against IRIS-projected FileMan tables (BMW.PATIENT, BMW.HOSPITAL_LOCATION, etc.) bypass nearly every protection FileMan provides:

- **INPUT TRANSFORM** — FileMan validates and reformats inbound values per field def. Bypassed.
- **TRIGGER cross-references** — Side-effect M code that fires on SET/KILL to maintain cascade updates, derived files. Bypassed.
- **Regular cross-references (XREFs)** — Automatically maintained on writes via FileMan API. Don't update.
- **MailMan notifications** — Many writes generate clinical alerts, supervisor approvals. Don't fire.
- **Audit log (file 1.1)** — FileMan auditing tracks writes through DIE/FILE^DIE. No audit entry on raw SQL.
- **Package-specific business rules** — BMC referral state transitions, BGO problem-list approval, PCC encounter validation, pharmacy ordering chains. All M code, all skipped on SQL writes.
- **PCC link maintenance (IHS)** — V-Lab / V-Med / V-Dx files cross-linked to PCC visits via M routines. Don't link on SQL writes.
- **DUZ-context computation** — Fields computed against the current user / DT / DUZ(2). SQL writes have no FileMan-aware DUZ context.

(BPRM v4's Adt module does raw SQL INSERT/UPDATE against BMW.* tables anyway. That's not an architectural endorsement; that's a cautionary tale. See conversation history for the source-level confirmation.)

Reads via SQL also have caveats — they don't apply OUTPUT TRANSFORMs and don't compute computed fields — so:

**Tier 1 (rpms-sql appropriate):** bulk counting, cohort building, dictionary / metadata access, reporting against stored fields that don't depend on transforms or computed fields. Examples: GPRA quality measures, FHIR ValueSet extraction from FileMan SET OF CODES, cohort building for population health.

**Tier 2 (rpms-rpc required):** clinical record loading, chart display, anywhere FileMan output transforms or computed fields are load-bearing for correctness. Patient charts, problem lists with rendered status text, medication orders with formatted prescriber strings.

When in doubt, fetch via both rpms-sql and rpms-rpc on the same record and compare. Any divergence is a transform or computed field that must be handled in Ruby or demoted to Tier 2.

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

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
