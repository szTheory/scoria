defmodule Scoria.SRE.AlertSink do
  @moduledoc """
  Behaviour for host-owned alert and incident delivery integrations.

  Implement this behaviour when Scoria should hand alert or incident envelopes
  to your paging, chat, ticketing, or incident-management system. Scoria shapes
  the envelope and keeps reviewer-visible evidence; the host app owns routing,
  escalation rules, credentials, acknowledgement policy, and the business
  meaning of each severity.

  Configure a sink in the host app when you are ready to connect operations
  tooling:

      config :scoria, :sre_alert_sink, MyApp.ScoriaAlertSink

  Keep the default no-op sink while proving the default runtime verification
  suite. See `guides/ownership-boundary.md` for the host-owned operations
  boundary and `guides/reviewer-verification.md` for the reviewer verification
  flow before adding optional SRE delivery.
  """

  @type envelope :: map()
  @type result :: {:ok, map()} | {:error, term()}

  @callback publish(envelope()) :: result()

  defmodule Noop do
    @moduledoc false

    @behaviour Scoria.SRE.AlertSink

    @impl true
    def publish(envelope), do: {:ok, %{status: :noop, envelope: envelope}}
  end
end
