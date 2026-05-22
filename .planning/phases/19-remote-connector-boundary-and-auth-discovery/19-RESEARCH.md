# Phase 19: Remote Connector Boundary and Auth Discovery - Research

**Researched:** 2026-05-17
**Domain:** Embedded Phoenix/Ecto remote connector boundary, MCP auth discovery, durable grant storage
**Confidence:** HIGH

## Summary

Phase 19 should introduce a Scoria-owned `Scoria.Connectors` boundary with three explicit durable nouns:

- `Connector` for app-facing registration truth, health state, and discovery timestamps
- `Grant` for one connector/account auth truth with encrypted secret fields plus operator-visible scope/expiry/refresh metadata
- `CapabilitySnapshot` for the current discovered remote catalog, catalog hash/version, discovery metadata URLs, refresh status, and staleness markers

This should follow the repo's existing preference for first-class Ecto rows, optimistic locking, and queryable operational columns instead of opaque metadata blobs or workflow metadata overload.

## Primary Recommendations

### Durable model

- Add a `Scoria.Connectors` context as the Scoria-owned boundary for registration, discovery, auth completion, and capability snapshot writes.
- Keep connector identity, grant state, and capability state in separate durable records rather than one mutable connector blob.
- Use first-class columns for operationally relevant fields such as status, scopes, expiry timestamps, refresh timestamps, health state, and catalog version/hash.
- Reserve bounded JSON/map fields for provider-specific or low-query metadata only.

### Registration and discovery posture

- Registration should normalize edge input through a `Params`-style module before durable writes.
- Registration/update should persist connector truth first, then enqueue explicit discovery work.
- Discovery should stay off the normal request/UI path and run through explicit jobs or supervised background work.
- Default refresh triggers should be explicit and durable: registration, auth completion, scope change, operator sync, invalidation/failure, and remote change notification where available.
- Avoid hidden periodic polling as the default behavior.

### Auth and callback posture

- The primary happy path should be browser redirect OAuth with PKCE.
- Host apps keep user login, actor/tenant resolution, and business authorization; Scoria owns remote auth plumbing, callback completion, grant durability, and operator-visible connector state.
- Callback state, PKCE verifier, and return target should remain transient; durable grant and connector state belongs in Ecto.
- Device flow and API key/client-credentials auth may exist as secondary paths, but they should not become the default Phase 19 story.

### Secret handling

- Encrypt access tokens, refresh tokens, client secrets, device codes, and raw token response fragments at rest.
- Keep non-secret metadata queryable and operator-visible: scopes, issuer/resource identifiers, expiry timestamps, refresh status, and redacted failure notes.
- Align persistence and evidence handling with existing SRE redaction and audit posture.

## Anti-Patterns To Avoid

- One mutable blob that mixes connector identity, grants, secrets, and capability state
- Durable token or client-secret storage in Plug session or cookies
- Request-time or LiveView-time implicit discovery
- Hosted-broker behavior or long-lived polling that breaks the embedded Phoenix posture
- Partial implementation of Phase 20 or 21 concerns inside Phase 19:
  - stable local tool identity
  - dual-plane policy enforcement
  - approval UX
  - full remote invocation evidence lineage

## Verification Implications

Planning should require four verification lanes:

1. Schema and service tests
   - connector registration persistence
   - grant encryption/redaction
   - optimistic locking
   - capability snapshot writes and updates
2. Auth flow tests
   - OAuth start/callback
   - invalid or replayed callback state rejection
   - expiry metadata persistence
   - post-auth refresh enqueueing
3. Job/background work tests
   - deduped discovery/refresh triggers
   - retry/error recording
   - explicit no-polling defaults
4. Integration tests
   - durable rows, audit/redaction behavior, and public Scoria boundary stay aligned
   - protocol details do not leak into normal request/UI code

## Phase-Slicing Guidance

The safest Phase 19 execution order is:

1. migrations and schemas
2. connector context and registration/discovery services
3. auth start/callback and durable grant handling
4. capability refresh orchestration and verification closeout

Dependencies on Phase 20 and later should remain explicit deferrals rather than partial early implementations.

---

*Phase: 19-remote-connector-boundary-and-auth-discovery*
*Research completed: 2026-05-17*
