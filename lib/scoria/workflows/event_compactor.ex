defmodule Scoria.Workflows.EventCompactor do
  @moduledoc false

  def maybe_enqueue_compaction(_repo, _run_id), do: :ok
end
