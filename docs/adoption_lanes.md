# Capability guide compatibility source page

Compatibility note: this old source path is kept so copied GitHub links to
`docs/adoption_lanes.md` continue to land somewhere useful.

The current guide names are **JTBD and User Flows** and **Default Runtime**:

- [`guides/jtbd-and-user-flows.md`](../guides/jtbd-and-user-flows.md) explains
  Scoria's jobs to be done, reviewer flow, capability ladder, and verification
  suites.
- [`guides/capabilities/default-runtime.md`](../guides/capabilities/default-runtime.md)
  is the first capability guide for the `identity -> start -> inspect -> resume`
  path.

The old "adoption lanes" name is compatibility context only. Current docs use
capabilities, reviewer verification, and verification suites.

## Scope doctrine compatibility notes

Scope doctrine mechanism-vs-noun boundary: Scoria owns the dashboard scope seam and trusted scope record; the host owns authentication, authorization, membership policy, and role values.

Scope doctrine mechanism-vs-noun boundary: Scoria owns retrieval filtering, citation validation, and persisted evidence; the host owns tenant/actor identity, business truth, and end-user semantics.

The host app supplies tenant/actor identity for this capability. Scoria enforces that scope at storage, retrieval, citation, and grounding boundaries; metadata filters can narrow results inside a tenant but are not security proof.

This compatibility page is not the canonical ExDoc source. Phase 48 moves the
guide ladder under `guides/`; this old `docs/` path exists only as a bridge for
0.1.x source links.
