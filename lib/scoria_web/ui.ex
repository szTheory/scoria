defmodule ScoriaWeb.UI do
  @moduledoc """
  Scoria's shared dashboard component vocabulary.

  Function components emit the brand-book semantic classes (see `assets/css/04-components.css`)
  driven entirely by design tokens. This is the single home for tone/status → color mapping,
  replacing the per-component `badge_class/status_color/trace_badge_class/flash_kind_class`
  helpers that previously drifted across the codebase.

  Import into a LiveView/component with `import ScoriaWeb.UI`.
  """
  use Phoenix.Component
  alias Phoenix.LiveView.JS

  @doc """
  Maps a domain status/kind string (or atom) to a semantic tone atom.

  Tones: `:pass | :info | :warn | :fail | :trace | :brand | :neutral`. Unknown values
  fall back to `:neutral`. This is the single source of truth for status coloring.
  """
  def tone(status) when is_atom(status), do: status |> Atom.to_string() |> tone()

  def tone(status) when is_binary(status) do
    case status do
      s
      when s in ~w(completed complete success succeeded online healthy ok pass passed available active resolved approved) ->
        :pass

      s
      when s in ~w(running streaming in_progress executing scheduled queued info reference retrieval) ->
        :info

      s
      when s in ~w(waiting_for_approval pending_approval retrying warning warn drift degraded stale pending approval_requested needs_review) ->
        :warn

      s
      when s in ~w(failed failure error offline denied rejected regression cancelled canceled unhealthy expired) ->
        :fail

      s when s in ~w(replay experiment branch candidate trace promotion_candidate online_eval) ->
        :trace

      _ ->
        :neutral
    end
  end

  def tone(_), do: :neutral

  @doc "Human label for a status string (title-cased, underscores → spaces)."
  def status_label(status) when is_atom(status), do: status |> Atom.to_string() |> status_label()

  def status_label(status) when is_binary(status) do
    status |> String.replace("_", " ") |> String.capitalize()
  end

  def status_label(_), do: "Unknown"

  attr(:tone, :atom, default: :neutral)
  attr(:label, :string, default: nil)
  attr(:dot, :boolean, default: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  @doc "Status badge. Always renders a text label alongside color (a11y: never color-alone)."
  def badge(assigns) do
    ~H"""
    <span class={["scoria-badge", "scoria-badge--#{@tone}", not @dot && "scoria-badge--bare", @class]} {@rest}>
      {@label}{render_slot(@inner_block)}
    </span>
    """
  end

  attr(:variant, :atom, default: :primary, values: [:primary, :ghost, :danger])
  attr(:size, :atom, default: :md, values: [:md, :sm])
  attr(:type, :string, default: "button")
  attr(:class, :string, default: nil)

  attr(:rest, :global,
    include:
      ~w(phx-click phx-value-id phx-value-approval-id phx-disable-with disabled form name value href)
  )

  slot(:inner_block, required: true)

  @doc "Primary/ghost/danger button (brand book §8.5)."
  def button(assigns) do
    ~H"""
    <button
      type={@type}
      class={["scoria-button", "scoria-button--#{@variant}", @size == :sm && "scoria-button--sm", @class]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  @doc "Small uppercase category/status label (brand book card eyebrow)."
  def eyebrow(assigns) do
    ~H"""
    <p class={["scoria-eyebrow", @class]}>{render_slot(@inner_block)}</p>
    """
  end

  attr(:variant, :atom, default: :flat, values: [:flat, :raised])
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:eyebrow)
  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Panel/card surface with optional eyebrow + title + actions header."
  def panel(assigns) do
    ~H"""
    <section class={["scoria-panel", @variant == :raised && "scoria-panel--raised", @class]} {@rest}>
      <div :if={@eyebrow != [] or @title != [] or @actions != []} class="scoria-panel__header">
        <div>
          <p :if={@eyebrow != []} class="scoria-eyebrow">{render_slot(@eyebrow)}</p>
          <h2 :if={@title != []}>{render_slot(@title)}</h2>
        </div>
        <div :if={@actions != []} class="flex items-center gap-2">{render_slot(@actions)}</div>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:label, :string, required: true)
  attr(:value, :string, required: true)
  attr(:delta, :string, default: nil)
  attr(:delta_tone, :atom, default: :neutral)
  attr(:class, :string, default: nil)

  @doc "Metric card: label, big value, explicit delta (brand book §11.3 — never a magic score)."
  def metric(assigns) do
    ~H"""
    <div class={["scoria-metric", @class]}>
      <p class="scoria-metric__label">{@label}</p>
      <p class="scoria-metric__value">{@value}</p>
      <p :if={@delta} class={["scoria-metric__delta", "scoria-metric__delta--#{@delta_tone}"]}>{@delta}</p>
    </div>
    """
  end

  attr(:value, :string, required: true)
  attr(:copy, :string, default: nil)
  attr(:class, :string, default: nil)

  @doc "Copyable monospace identifier (run/trace/actor IDs). Uses the CopyId JS hook."
  def id(assigns) do
    ~H"""
    <span class={["scoria-id", @class]} phx-hook="CopyId" id={"id-#{System.unique_integer([:positive])}"} data-copy={@copy || @value} title="Click to copy">
      {@value}
    </span>
    """
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: nil)
  slot(:inner_block)
  slot(:action)

  @doc "Empty state: status + learning cue + optional primary action (NN/g)."
  def empty_state(assigns) do
    ~H"""
    <div class={["scoria-empty", @class]}>
      <p class="scoria-empty__title">{@title}</p>
      <div :if={@inner_block != []}>{render_slot(@inner_block)}</div>
      <div :if={@action != []} class="mt-4 flex justify-center">{render_slot(@action)}</div>
    </div>
    """
  end

  attr(:flash, :map, default: %{})

  @doc "Dashboard flash banners. Single home for flash kind → tone styling (DS-05).
  Renders semantic scoria-flash--{tone} BEM modifier classes via string-keyed clauses
  (Phoenix @flash always provides string keys, not atoms). Each banner carries
  role=\"alert\" and a 16×16 tone icon so status is never communicated by color alone."
  def flash_group(assigns) do
    ~H"""
    <div
      :for={{kind, message} <- @flash}
      id={"flash-#{kind}"}
      role="alert"
      class={["scoria-flash", flash_modifier(kind)]}
    >
      {flash_icon(kind)}
      {message}
    </div>
    """
  end

  defp flash_modifier("error"), do: "scoria-flash--fail"
  defp flash_modifier("info"), do: "scoria-flash--info"
  defp flash_modifier("success"), do: "scoria-flash--pass"
  defp flash_modifier(_kind), do: "scoria-flash--warn"

  # 16×16 inline SVG tone icons — status never by color alone (a11y DS-05).
  defp flash_icon("error") do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zM7 5a1 1 0 1 1 2 0v3a1 1 0 1 1-2 0V5zm1 6.25a1.25 1.25 0 1 0 0-2.5 1.25 1.25 0 0 0 0 2.5z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp flash_icon("info") do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 3a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm-1 4a1 1 0 0 1 1-1h.01a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V8z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp flash_icon("success") do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm3.78 5.78a.75.75 0 0 0-1.06-1.06L7 9.44 5.28 7.72a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.06 0l4.25-4.25z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp flash_icon(_kind) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8.22 1.3a.25.25 0 0 0-.44 0L.36 14.26a.25.25 0 0 0 .22.37h14.84a.25.25 0 0 0 .22-.37L8.22 1.3zm-.72 4.7a.5.5 0 0 1 1 0v3a.5.5 0 0 1-1 0V6zm.75 5.5a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0z" clip-rule="evenodd" />
    </svg>
    """
  end
end
