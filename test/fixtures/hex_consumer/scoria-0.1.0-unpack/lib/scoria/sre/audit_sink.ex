defmodule Scoria.SRE.AuditSink do
  @moduledoc """
  Behavior for optional audit export sinks.

  Sinks receive redacted envelope maps instead of internal structs so core Scoria
  stays decoupled from downstream relay libraries.
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
