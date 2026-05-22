## Plan 21-03 Summary

- Added `Scoria.Connectors.Remediation` for typed non-approval remediation actions.
- Added `Scoria.Connectors.EvidenceProjection` plus `Scoria.Connectors.remote_invocation_evidence/1` and `Scoria.SRE.remote_invocation_evidence/1` for run-centric remote evidence reads.
- Kept approval outcomes narrow while separating replay/remediation actions from approval status.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/observe/approval_test.exs test/scoria/workflows_test.exs test/scoria/connectors/invocation_test.exs test/scoria/sre/telemetry_test.exs`
