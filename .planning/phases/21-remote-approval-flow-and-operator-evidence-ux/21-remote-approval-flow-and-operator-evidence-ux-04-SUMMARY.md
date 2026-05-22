## Plan 21-04 Summary

- Added `ScoriaWeb.RemoteInvocationEvidenceComponent` and wired `ScoriaWeb.WorkflowLive.Show` to render a lineage-first remote evidence notebook on workflow runs.
- Expanded `Scoria.SRE.TelemetryIdentity.refs/1` so exact approval, connector, local-tool, audit, and workflow-event ids stay in refs rather than low-cardinality labels.
- Verified the workflow run page and telemetry identity contract against the new remote evidence seam.

## Verification

- `SCORIA_DB_PORT=55432 MIX_ENV=test mix test test/scoria/sre/telemetry_test.exs test/scoria_web/live/workflow_live_test.exs`
