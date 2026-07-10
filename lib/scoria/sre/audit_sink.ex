defmodule Scoria.SRE.AuditSink do
  @moduledoc """
  Behaviour for host-owned audit export integrations.

  Implement this behaviour when Scoria audit outbox events should be relayed to
  a SIEM, archive, compliance queue, or internal audit service. Scoria provides
  redacted envelope maps and reviewer-visible delivery evidence; the host app
  owns retention policy, export destination, credentials, and downstream
  compliance interpretation.

  Configure a sink in the host app when audit export is part of your operating
  model:

      config :scoria, :sre_audit_sink, MyApp.ScoriaAuditSink

  Keep the default no-op sink for first-run adoption. See
  `guides/ownership-boundary.md` for the host-owned audit policy boundary; the
  reviewer verification suite in `guides/reviewer-verification.md` proves the
  runtime and dashboard boundary before optional audit export is wired.
  """

  @type envelope :: map()
  @type result :: {:ok, map()} | {:error, term()}

  @callback publish(envelope()) :: result()

  defmodule Noop do
    @moduledoc false

    @behaviour Scoria.SRE.AuditSink

    @impl true
    def publish(envelope), do: {:ok, %{status: :noop, envelope: envelope}}
  end
end
