# API Coverage — Phase 57 (Confluence Escalation Gate)

No external API integration: this phase and its gap-closure plans (57-11, 57-12) wire
internal Elixir/Ecto read paths — `Scoria.Workflows.RemoteApprovalProjection` reading a
`Scoria.SRE.AuditOutboxEvent` row written by `Scoria.MCP.Executor`, rendered through
`ScoriaWeb.ApprovalCopy` — plus in-repo planning bookkeeping. No external service, SDK,
HTTP client, webhook, or third-party endpoint is called, added, or wrapped.

The deterministic detector fires on this phase only because Scoria's own internal module
namespace `Scoria.MCP.Executor` matches the `mcp` noun in the trigger vocabulary; `MCP` here
is the in-repo tool-execution choke point, not an integration against an external
Model Context Protocol server.
