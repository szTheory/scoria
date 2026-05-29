defmodule Scoria.Compaction.SummarizeWorker do
  @moduledoc """
  Summarizes uncompacted workflow events into durable compacted memories.
  """

  use Oban.Worker,
    queue: :compaction,
    unique: [
      period: 60,
      fields: [:worker, :args],
      keys: [:run_id],
      states: [:available, :scheduled, :executing, :retryable]
    ]

  import Ecto.Query, warn: false

  alias Ecto.Multi
  alias Oban.Job
  alias ReqLLM.Response
  alias Scoria.Repo
  alias Scoria.Runtime.CompactedMemory
  alias Scoria.Workflows.{Event, Run}

  @default_summary_model "openai:gpt-4o-mini"
  @default_embedding_model "openai:text-embedding-3-small"

  @impl Oban.Worker
  def perform(%Job{args: %{"run_id" => run_id}}) do
    case fetch_run_events(run_id) do
      {nil, _events} ->
        {:error, :run_not_found}

      {%Run{} = _run, []} ->
        :ok

      {%Run{} = run, events} ->
        summarize_run(run, events)
    end
  end

  def new_job(args, opts \\ []) do
    args
    |> Map.new()
    |> Map.take([:run_id, "run_id"])
    |> normalize_args()
    |> new(opts)
  end

  defp summarize_run(run, events) do
    prompt = build_prompt(run, events)
    summary_text = generate_summary!(prompt)
    embedding = generate_embedding(summary_text)
    compacted_at = DateTime.utc_now() |> DateTime.truncate(:microsecond)
    token_count = Enum.reduce(events, 0, fn event, total -> total + event_token_count(event) end)
    start_sequence = hd(events).sequence
    end_sequence = List.last(events).sequence
    event_ids = Enum.map(events, & &1.id)

    Multi.new()
    |> Multi.insert(
      :memory,
      CompactedMemory.changeset(%CompactedMemory{}, %{
        run_id: run.id,
        session_id: run.session_id || run.id,
        start_sequence: start_sequence,
        end_sequence: end_sequence,
        summary_text: summary_text,
        embedding: embedding,
        token_count: token_count
      })
    )
    |> Multi.update_all(
      :events,
      from(event in Event, where: event.id in ^event_ids),
      set: [compacted_at: compacted_at, updated_at: compacted_at]
    )
    |> Repo.transaction()
    |> case do
      {:ok, _changes} -> :ok
      {:error, _step, reason, _changes} -> {:error, reason}
    end
  end

  defp fetch_run_events(run_id) do
    run = Repo.get(Run, run_id)

    events =
      Event
      |> where([event], event.run_id == ^run_id and is_nil(event.compacted_at))
      |> order_by([event], asc: event.sequence)
      |> Repo.all()

    {run, events}
  end

  defp build_prompt(run, events) do
    body =
      events
      |> Enum.map_join("\n", fn event ->
        payload = Jason.encode!(event.payload || %{})
        "[#{event.sequence}] #{event.event_type}: #{payload}"
      end)

    """
    Summarize the following workflow events into a concise session memory.
    Preserve important decisions, approvals, failures, and outcomes.

    Run ID: #{run.id}
    Session ID: #{run.session_id || "unknown"}

    Events:
    #{body}
    """
  end

  defp generate_summary!(prompt) do
    orchestrator_module = Application.get_env(:scoria, :orchestrator_module, Scoria.Orchestrator)

    with {:ok, response} <-
           orchestrator_module.generate_text(summary_model(), prompt,
             system_prompt:
               "You compress workflow event history into durable operational memory for later retrieval."
           ),
         summary when is_binary(summary) and summary != "" <- extract_summary_text(response) do
      summary
    else
      {:error, reason} -> raise "compaction summary failed: #{inspect(reason)}"
      _ -> raise "compaction summary returned no text"
    end
  end

  defp generate_embedding(summary_text) do
    embedding_module = Application.get_env(:scoria, :req_llm_embedding_module, ReqLLM.Embedding)

    case embedding_module.embed(embedding_model(), summary_text, dimensions: 3) do
      {:ok, embedding} when is_list(embedding) -> :erlang.term_to_binary(embedding)
      {:ok, %{embedding: embedding}} when is_list(embedding) -> :erlang.term_to_binary(embedding)
      _ -> nil
    end
  end

  defp extract_summary_text(%Response{} = response), do: Response.text(response)
  defp extract_summary_text(%{text: text}) when is_binary(text), do: text
  defp extract_summary_text(%{"text" => text}) when is_binary(text), do: text
  defp extract_summary_text(text) when is_binary(text), do: text
  defp extract_summary_text(_response), do: nil

  defp event_token_count(event) do
    Scoria.Compaction.Tokenizer.estimate(event.event_type) +
      Scoria.Compaction.Tokenizer.estimate(event.payload)
  end

  defp normalize_args(%{"run_id" => run_id}), do: %{run_id: run_id}
  defp normalize_args(%{run_id: run_id}), do: %{run_id: run_id}

  defp summary_model do
    Application.get_env(:scoria, __MODULE__, [])
    |> Keyword.get(:summary_model, @default_summary_model)
  end

  defp embedding_model do
    Application.get_env(:scoria, __MODULE__, [])
    |> Keyword.get(:embedding_model, @default_embedding_model)
  end
end
