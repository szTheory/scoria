defmodule Scoria.Confluence.Evidence do
  @moduledoc """
  Closed evidence struct backing `Scoria.Confluence.classify/1`'s second
  tuple element (D-04). Mirrors `%Scoria.MCP.Classification{}`'s closed-set
  discipline (`classification.ex:38-45`): every field is an enum, id,
  boolean, or timestamp, and the struct carries no `:reason`, `:note`, or
  `:score` free-text field. `@derive Jason.Encoder` for the same reason
  `%Scoria.MCP.Classification{}` does -- a resolved evidence struct may
  flow into a context a host later encodes to JSON.

  Field names beyond `:combination`/`:grade`/`:decision`/the three leg
  witness fields/`:confluence_idempotency_key` are executor discretion per
  `57-CONTEXT.md`'s "Claude's Discretion" section.
  """

  @derive Jason.Encoder
  @enforce_keys [:combination]
  defstruct [
    :combination,
    :grade,
    :decision,
    :reason_code,
    :private_data_source,
    :untrusted_content_source,
    :exfil_source,
    :action_class,
    :confluence_idempotency_key,
    :run_id,
    :step_id,
    :tool_ref
  ]

  @type t :: %__MODULE__{
          combination: String.t() | :unevaluable,
          grade: String.t() | nil,
          decision: String.t() | nil,
          reason_code: atom() | nil,
          private_data_source: atom() | nil,
          untrusted_content_source: atom() | nil,
          exfil_source: atom() | nil,
          action_class: String.t() | nil,
          confluence_idempotency_key: String.t() | nil,
          run_id: term() | nil,
          step_id: term() | nil,
          tool_ref: String.t() | nil
        }
end
