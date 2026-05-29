defmodule Scoria.SRE.AlertSink do
  @moduledoc """
  Behavior for optional alert delivery sinks.

  Sinks receive severity-shaped envelopes so later plans can route incidents and
  notifications without hard vendor coupling.
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
