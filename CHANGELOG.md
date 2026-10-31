# Changelog

## Unreleased

- License is now Apache-2.0 (`LICENSE`, `NOTICE`). Earlier releases stay available under the MIT License, whose notice is kept in `NOTICE`.
- Initial scaffolding: `RpmsSql::Client` (pg-backed), `RpmsSql::MockClient`, configuration accessors mirroring rpms-rpc.
- Hard read-only enforcement: `SqlSafety.assert_read_only!` rejects any non-read SQL with `Client::ReadOnlyViolation`. Writes must go through rpms-rpc so FileMan business logic fires.
