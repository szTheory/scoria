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
      ~w(phx-click phx-target phx-value-id phx-value-approval-id phx-value-dataset-id phx-disable-with disabled form name value href) ++
        ~w(aria-current)
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

  attr(:variant, :atom, default: :ghost, values: [:primary, :ghost, :danger])
  attr(:size, :atom, default: :md, values: [:md, :sm])
  attr(:type, :string, default: "button")
  attr(:class, :string, default: nil)

  attr(:rest, :global,
    include: ~w(phx-click phx-target phx-value-id phx-disable-with disabled autofocus)
  )

  slot(:inner_block, required: true)

  @doc "Icon-only button. Use `size: :md` for chrome controls and `size: :sm` for inline utilities."
  def icon_button(assigns) do
    ~H"""
    <button
      type={@type}
      class={[
        "scoria-button",
        "scoria-button--#{@variant}",
        "scoria-button--sm",
        "scoria-button--icon",
        "scoria-button--icon-#{@size}",
        @class
      ]}
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr(:class, :string, default: nil)
  slot(:inner_block)

  @doc "Small uppercase category/status label (brand book card eyebrow).
Used in panel headers, object headers, and card hierarchy labeling to
provide a typographic tier above the primary title."
  def eyebrow(assigns) do
    ~H"""
    <p class={["scoria-eyebrow", @class]}>{render_slot(@inner_block)}</p>
    """
  end

  attr(:variant, :atom, default: :flat, values: [:flat, :raised])
  attr(:flush, :boolean, default: false)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:eyebrow)
  slot(:title)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Panel/card surface with optional eyebrow + title + actions header."
  def panel(assigns) do
    ~H"""
    <section
      class={[
        "scoria-panel",
        @variant == :raised && "scoria-panel--raised",
        @flush && "scoria-panel--flush",
        @class
      ]}
      {@rest}
    >
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

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:eyebrow)
  slot(:title)
  slot(:description)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc """
  Open-air top-level page section.

  Use this for primary page regions that should breathe on the canvas. Use
  `panel/1` only when the UI needs a contained object, evidence, table, drawer,
  or modal surface.
  """
  def page_section(assigns) do
    ~H"""
    <section class={["scoria-page-section", @class]} {@rest}>
      <div
        :if={@eyebrow != [] or @title != [] or @description != [] or @actions != []}
        class="scoria-page-section__header"
      >
        <div class="scoria-page-section__heading">
          <p :if={@eyebrow != []} class="scoria-eyebrow">{render_slot(@eyebrow)}</p>
          <h2 :if={@title != []}>{render_slot(@title)}</h2>
          <p :if={@description != []} class="scoria-page-section__description">
            {render_slot(@description)}
          </p>
        </div>
        <div :if={@actions != []} class="scoria-page-section__actions">
          {render_slot(@actions)}
        </div>
      </div>
      {render_slot(@inner_block)}
    </section>
    """
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:summary)
  slot(:actions)

  @doc """
  Page-level heading — owns the single `<h1>` for a dashboard page.

  `title` is a required plain-string attr, not a slot, so schema/module names or
  opaque IDs cannot be interpolated into the page's only `<h1>` (D-01/D-23/D-26).
  Use the `:summary` slot for a one-line operator-orientation `<p>` and the
  `:actions` slot for at most one header action (a primary action or a
  ghost/secondary nav link, e.g. review_queue's "Back to dashboard" link).
  """
  def page_header(assigns) do
    ~H"""
    <div class={["scoria-pagehead", @class]} {@rest}>
      <div class={[
        "scoria-pagehead__title",
        @actions != [] && "scoria-pagehead__title--with-actions"
      ]}>
        <h1>{@title}</h1>
        <div :if={@actions != []}>{render_slot(@actions)}</div>
      </div>
      <p :if={@summary != []} class="scoria-pagehead__description">
        {render_slot(@summary)}
      </p>
    </div>
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

  attr(:label, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  slot(:stat, required: true) do
    attr(:label, :string, required: true)
    attr(:value, :string, required: true)
    attr(:tone, :atom)
  end

  @doc """
  Plain-language overview stats for page-level operational summaries.

  Use this instead of `metric/1` when a count needs context or an operator
  needs to understand what action the number implies.
  """
  def overview_stats(assigns) do
    ~H"""
    <dl class={["scoria-overview-stats", @class]} aria-label={@label} {@rest}>
      <div
        :for={stat <- @stat}
        class={["scoria-overview-stat", "scoria-overview-stat--#{stat[:tone] || :neutral}"]}
      >
        <dt class="scoria-overview-stat__label">{stat.label}</dt>
        <dd class="scoria-overview-stat__value">{stat.value}</dd>
        <dd class="scoria-overview-stat__detail">{render_slot(stat)}</dd>
      </div>
    </dl>
    """
  end

  attr(:value, :string, required: true)
  attr(:copy, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:title, :string, default: "Click to copy")
  attr(:class, :string, default: nil)

  @doc "Copyable monospace identifier (run/trace/actor IDs). Uses the CopyId JS hook.

  The DOM id must be stable across renders so LiveView/morphdom patches the existing
  element in place rather than tearing down and re-mounting the CopyId hook. When no
  caller-supplied id is given it is derived deterministically from the displayed value;
  prefer passing an explicit id where two identical values can appear on one page."
  def id(assigns) do
    assigns =
      assign_new(assigns, :id, fn ->
        "id-" <> Integer.to_string(:erlang.phash2(assigns.value))
      end)

    ~H"""
    <span
      class={["scoria-id", @class]}
      phx-hook="CopyId"
      id={@id}
      data-copy={@copy || @value}
      title={@title}
      aria-label={"Copy " <> @value}
      aria-live="polite"
    >
      {@value}
    </span>
    """
  end

  attr(:at, :any, required: true)
  attr(:mode, :atom, default: :absolute, values: [:absolute, :elapsed])
  attr(:fallback, :string, default: "Not recorded")
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  @doc "Machine-readable time with operator-friendly visible text and exact timestamp tooltip."
  def time(assigns) do
    assigns =
      assigns
      |> assign(:datetime, datetime_attr(assigns.at))
      |> assign(:exact, exact_time(assigns.at, assigns.fallback))
      |> assign(:label, time_label(assigns.at, assigns.mode, assigns.fallback))

    ~H"""
    <time
      :if={@datetime}
      datetime={@datetime}
      title={@exact}
      class={["scoria-time", @class]}
      {@rest}
    >
      {@label}
    </time>
    <span :if={!@datetime} class={["scoria-time", @class]} {@rest}>{@label}</span>
    """
  end

  defp datetime_attr(%DateTime{} = dt), do: DateTime.to_iso8601(dt)
  defp datetime_attr(_), do: nil

  defp time_label(%DateTime{} = dt, :elapsed, _fallback), do: "Waiting #{elapsed_label(dt)}"
  defp time_label(%DateTime{} = dt, _mode, _fallback), do: exact_time(dt, nil)
  defp time_label(nil, _mode, fallback), do: fallback
  defp time_label(other, _mode, _fallback), do: to_string(other)

  defp exact_time(%DateTime{} = dt, _fallback) do
    dt
    |> DateTime.shift_zone!("Etc/UTC")
    |> Calendar.strftime("%Y-%m-%d %H:%M UTC")
  end

  defp exact_time(nil, fallback), do: fallback
  defp exact_time(other, _fallback), do: to_string(other)

  defp elapsed_label(%DateTime{} = dt) do
    now = DateTime.utc_now()
    seconds = max(DateTime.diff(now, dt, :second), 0)

    cond do
      seconds < 60 -> "just now"
      seconds < 3_600 -> "#{div(seconds, 60)}m"
      seconds < 86_400 -> "#{div(seconds, 3_600)}h"
      seconds < 604_800 -> "#{div(seconds, 86_400)}d"
      true -> Calendar.strftime(dt, "%Y-%m-%d")
    end
  end

  attr(:count, :any, required: true)
  attr(:label, :string, required: true)
  attr(:detail, :string, required: true)
  attr(:cta, :string, required: true)
  attr(:path, :string, required: true)
  attr(:tone, :atom, default: :neutral)
  attr(:class, :string, default: nil)

  @doc "Status Home attention strip card for nonzero actionable states.
Renders as an `<a>` tag — callers pass a `path`, not a click handler.
Attrs: `count` (numeric highlight), `label` (category name), `detail`
(supporting copy), `cta` (call-to-action text), `path` (link target),
`tone` (semantic tone atom controlling color treatment, default `:neutral`)."
  def attention_card(assigns) do
    ~H"""
    <a href={@path} class={["scoria-attention-card", "scoria-attention-card--#{@tone}", @class]}>
      <span class="scoria-attention-card__count">{@count}</span>
      <span class="scoria-attention-card__body">
        <span class="scoria-attention-card__label">{@label}</span>
        <span class="scoria-attention-card__detail">{@detail}</span>
      </span>
      <span class="scoria-attention-card__cta">{@cta}</span>
    </a>
    """
  end

  attr(:href, :string, default: nil)
  attr(:selected, :boolean, default: false)
  attr(:tone, :atom, default: :neutral)
  attr(:class, :string, default: nil)
  attr(:type, :string, default: "button")
  attr(:rest, :global)
  slot(:title, required: true)
  slot(:status)
  slot(:meta)

  @doc "Selectable object card for list/detail navigation. Use links for routed objects."
  def selectable_card(assigns) do
    assigns =
      assign(
        assigns,
        :card_class,
        [
          "scoria-selectable-card",
          "scoria-selectable-card--#{assigns.tone}",
          assigns.selected && "scoria-selectable-card--selected",
          assigns.class
        ]
      )

    ~H"""
    <a :if={@href} href={@href} class={@card_class} {@rest}>
      <span class="scoria-selectable-card__body">
        <span class="scoria-selectable-card__title">{render_slot(@title)}</span>
        <span :if={@meta != []} class="scoria-selectable-card__meta">{render_slot(@meta)}</span>
      </span>
      <span :if={@status != []} class="scoria-selectable-card__status">{render_slot(@status)}</span>
    </a>

    <button :if={!@href} type={@type} class={@card_class} {@rest}>
      <span class="scoria-selectable-card__body">
        <span class="scoria-selectable-card__title">{render_slot(@title)}</span>
        <span :if={@meta != []} class="scoria-selectable-card__meta">{render_slot(@meta)}</span>
      </span>
      <span :if={@status != []} class="scoria-selectable-card__status">{render_slot(@status)}</span>
    </button>
    """
  end

  attr(:parent_label, :string, required: true)
  attr(:parent_path, :string, required: true)
  attr(:object_type, :string, required: true)
  attr(:object_id, :string, required: true)
  attr(:status, :any, default: nil)
  attr(:key_scalar, :string, default: nil)
  attr(:provenance, :string, default: nil)
  attr(:origin, :map, default: nil)
  attr(:class, :string, default: nil)
  attr(:id, :string, default: nil)
  attr(:rest, :global)

  @doc "Object-page orientation header: parent crumb, copyable ID, status, provenance, and return context."
  def object_header(assigns) do
    assigns =
      assigns
      |> assign(:display_id, middle_truncate(assigns.object_id))
      |> assign(:status_text, assigns.status && status_label(assigns.status))
      |> assign(:status_tone, assigns.status && tone(assigns.status))
      |> assign(:origin_label, origin_label(assigns.origin))

    ~H"""
    <header
      id={@id || "scoria-object-header-#{:erlang.phash2(@object_id)}"}
      class={["scoria-object-header", @class]}
      phx-hook="RecordRecentObject"
      data-scoria-kind={@object_type}
      data-scoria-id={@object_id}
      data-scoria-label={"#{@object_type} #{@display_id}"}
      {@rest}
    >
      <nav class="scoria-object-header__crumbs" aria-label="Object breadcrumbs">
        <a href={@parent_path}>{@parent_label}</a>
        <span class="scoria-breadcrumbs__sep" aria-hidden="true">/</span>
        <span title={@object_id}>{@display_id}</span>
      </nav>
      <div class="scoria-object-header__identity">
        <.badge tone={:neutral} label={@object_type} />
        <.id
          id={"object-id-#{:erlang.phash2(@object_id)}"}
          value={@display_id}
          copy={@object_id}
          title={@object_id}
          class="scoria-object-header__id"
        />
        <.badge :if={@status_text} tone={@status_tone} label={@status_text} />
        <span :if={@key_scalar} class="scoria-object-header__scalar">{@key_scalar}</span>
      </div>
      <div :if={@provenance || @origin_label} class="scoria-object-header__context">
        <p :if={@provenance} class="scoria-object-header__provenance">{@provenance}</p>
        <a :if={@origin_label} class="scoria-object-header__origin" href={@origin.path}>
          {@origin_label}
        </a>
      </div>
    </header>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, required: true)
  attr(:works_today, :list, default: [])
  attr(:tracking_url, :string, default: nil)
  attr(:class, :string, default: nil)

  @doc "Honest reserved-capability stub page. Future-tense only; no fake rows or charts."
  def stub_page(assigns) do
    ~H"""
    <section class={["scoria-stub", @class]}>
      <div class="scoria-stub__header">
        <h1>{@title}</h1>
        <.badge tone={:neutral} label="Soon" />
      </div>
      <p class="scoria-stub__description">{@description}</p>
      <div class="scoria-stub__today">
        <h2>What works today</h2>
        <ul>
          <li :for={item <- @works_today}>
            <a href={Map.fetch!(item, :path)}>{Map.fetch!(item, :label)}</a>
          </li>
        </ul>
      </div>
      <a :if={@tracking_url} class="scoria-stub__track" href={@tracking_url}>
        Track progress
      </a>
    </section>
    """
  end

  attr(:class, :string, default: nil)
  slot(:inner_block, required: true)

  @doc "Keyboard shortcut chip. Renders a `<kbd>` element styled with the
brand-book monospace treatment. Used inline in command palette rows and
help text to label key bindings (e.g. `⌘K`, `Escape`, `↑↓`)."
  def kbd(assigns) do
    ~H"""
    <kbd class={["scoria-kbd", @class]}>{render_slot(@inner_block)}</kbd>
    """
  end

  attr(:id, :string, required: true)
  attr(:sections, :list, default: [])
  attr(:title, :string, default: "Open command palette")
  attr(:placeholder, :string, default: "Search screens, recent objects, and actions")

  attr(:empty_copy, :string,
    default:
      "No matches. The palette covers screens, recent objects, and actions — full object search lands in a later release."
  )

  attr(:class, :string, default: nil)

  @doc "Server-rendered command palette shell. Client-side filtering lives in assets/js/scoria.js."
  def command_palette(assigns) do
    assigns = assign(assigns, :active_id, first_command_id(assigns.sections))

    ~H"""
    <div
      id={@id}
      class={["scoria-command", @class]}
      role="dialog"
      aria-modal="true"
      aria-labelledby={"#{@id}-title"}
      phx-hook="CommandPalette"
      data-state="closed"
    >
      <div class="scoria-command__scrim" data-command-close aria-hidden="true"></div>
      <section class="scoria-command__panel">
        <header class="scoria-command__header">
          <h2 id={"#{@id}-title"}>{@title}</h2>
          <.kbd>Esc</.kbd>
        </header>
        <input
          id={"#{@id}-input"}
          class="scoria-command__input"
          type="search"
          placeholder={@placeholder}
          autocomplete="off"
          data-command-input
        />
        <div
          id={"#{@id}-listbox"}
          class="scoria-command__list"
          role="listbox"
          aria-activedescendant={@active_id}
          data-command-list
        >
          <section :for={section <- @sections} class="scoria-command__section" data-command-section>
            <h3>{Map.fetch!(section, :label)}</h3>
            <div class="scoria-command__rows">
              <%= for row <- Map.get(section, :rows, []) do %>
                <a
                  :if={command_row_path(row)}
                  id={command_row_id(row)}
                  href={command_row_path(row)}
                  class="scoria-command__row"
                  role="option"
                  aria-selected="false"
                  data-command-row
                  data-command-kbd={command_row_kbd(row)}
                  data-command-search={command_row_search(row)}
                >
                  <span>
                    <span class="scoria-command__label">{command_row_label(row)}</span>
                    <.badge :if={Map.get(row, :soon?, false)} tone={:neutral} label="Soon" />
                  </span>
                  <.kbd :if={command_row_kbd(row)}>{command_row_kbd(row)}</.kbd>
                </a>
                <button
                  :if={!command_row_path(row)}
                  id={command_row_id(row)}
                  type="button"
                  class="scoria-command__row"
                  role="option"
                  aria-selected="false"
                  data-command-row
                  data-command-action={Map.get(row, :action)}
                  data-command-kbd={command_row_kbd(row)}
                  data-command-search={command_row_search(row)}
                >
                  <span class="scoria-command__label">{command_row_label(row)}</span>
                  <.kbd :if={command_row_kbd(row)}>{command_row_kbd(row)}</.kbd>
                </button>
              <% end %>
            </div>
          </section>
          <p class="scoria-command__empty" data-command-empty hidden>{@empty_copy}</p>
        </div>
      </section>
    </div>
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

  # ---------------------------------------------------------------------------
  # DS-02: <.modal> and <.drawer> — slot-based overlay shells (plan 12-03)
  # ---------------------------------------------------------------------------

  attr(:id, :string, required: true)
  attr(:show, :boolean, required: true)
  attr(:on_dismiss, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:max_width, :string, default: "560px")
  attr(:rest, :global)
  slot(:title_slot)
  slot(:inner_block, required: true)
  slot(:footer)

  @doc "Slot-based modal dialog shell (DS-02).
  Renders nothing when show=false. When show=true, renders a scrim + panel with
  a consistent triple dismiss contract: close button + scrim click + Escape key.
  The caller owns all dismiss events via on_dismiss."
  def modal(assigns) do
    ~H"""
    <div :if={@show} id={@id} class="scoria-modal" phx-window-keydown={@on_dismiss} phx-key="Escape" {@rest}>
      <div class="scoria-scrim" phx-click={@on_dismiss} aria-hidden="true"></div>
      <div
        class="scoria-modal__panel"
        role="dialog"
        aria-modal="true"
        aria-labelledby={(@title_slot != [] or @title != nil) && "#{@id}-title"}
        style={"max-width: #{@max_width}"}
      >
        <div class="scoria-modal__header">
          <div>
            <h2 :if={@title_slot != []} id={"#{@id}-title"}>{render_slot(@title_slot)}</h2>
            <h2 :if={@title_slot == [] and @title != nil} id={"#{@id}-title"}>{@title}</h2>
          </div>
          <.icon_button
            autofocus
            phx-click={@on_dismiss}
            size={:md}
            aria-label="Close dialog"
            title="Close dialog"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
              <path fill-rule="evenodd" d="M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.75.75 0 1 1 1.06 1.06L9.06 8l3.22 3.22a.75.75 0 1 1-1.06 1.06L8 9.06l-3.22 3.22a.75.75 0 0 1-1.06-1.06L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06z" clip-rule="evenodd" />
            </svg>
          </.icon_button>
        </div>
        <div class="scoria-modal__body">
          {render_slot(@inner_block)}
        </div>
        <div :if={@footer != []} class="scoria-modal__footer">
          {render_slot(@footer)}
        </div>
      </div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:show, :boolean, required: true)
  attr(:on_dismiss, :string, required: true)
  attr(:title, :string, default: nil)
  attr(:rest, :global)
  slot(:eyebrow)
  slot(:title_slot)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Slot-based drawer panel shell (DS-02).
  Renders nothing when show=false. When show=true, renders a scrim + aside panel with
  a consistent triple dismiss contract: close button + scrim click + Escape key.
  The caller owns all dismiss events via on_dismiss."
  def drawer(assigns) do
    ~H"""
    <div :if={@show} id={@id} class="scoria-drawer-shell" {@rest}>
      <div
        class="scoria-scrim"
        phx-click={@on_dismiss}
        phx-window-keydown={@on_dismiss}
        phx-key="Escape"
        aria-hidden="true"
      ></div>
      <aside
        class="scoria-drawer"
        role="dialog"
        aria-modal="true"
        aria-labelledby={(@title_slot != [] or @title != nil) && "#{@id}-title"}
      >
        <div class="scoria-drawer__header">
          <div class="scoria-drawer__header-text">
            <p :if={@eyebrow != []} class="scoria-eyebrow">{render_slot(@eyebrow)}</p>
            <h2 :if={@title_slot != []} id={"#{@id}-title"}>{render_slot(@title_slot)}</h2>
            <h2 :if={@title_slot == [] and @title != nil} id={"#{@id}-title"}>{@title}</h2>
          </div>
          <div class="scoria-drawer__header-actions">
            <div :if={@actions != []}>{render_slot(@actions)}</div>
            <.icon_button
              phx-click={@on_dismiss}
              size={:md}
              aria-label="Close drawer"
              title="Close drawer"
            >
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
                <path fill-rule="evenodd" d="M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.75.75 0 1 1 1.06 1.06L9.06 8l3.22 3.22a.75.75 0 1 1-1.06 1.06L8 9.06l-3.22 3.22a.75.75 0 0 1-1.06-1.06L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06z" clip-rule="evenodd" />
              </svg>
            </.icon_button>
          </div>
        </div>
        <div class="scoria-drawer__body">
          {render_slot(@inner_block)}
        </div>
      </aside>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # DS-03: <.field> and <.form_section> — form control wrappers (plan 12-03)
  # ---------------------------------------------------------------------------

  attr(:id, :string, required: true)
  attr(:label, :string, required: true)
  attr(:help, :string, default: nil)
  attr(:error, :string, default: nil)
  attr(:required, :boolean, default: false)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @doc "Form field wrapper (DS-03).
  Renders a label + caller-provided input slot + optional help text + validation error.
  Error is surfaced via an exclamation icon + text (never error by color alone).
  Required fields include an aria-hidden asterisk and a visually-hidden '(required)' span.
  The caller provides the actual input/select/textarea element via the inner_block slot."
  def field(assigns) do
    ~H"""
    <div class="scoria-field" {@rest}>
      <label for={@id} class="scoria-field__label">
        {@label}
        <span :if={@required} aria-hidden="true" style="color: var(--scoria-danger-action)">*</span>
        <span :if={@required} class="sr-only">(required)</span>
      </label>
      {render_slot(@inner_block)}
      <p :if={@help} class="scoria-field__help">{@help}</p>
      <p :if={@error} class="scoria-field__error">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 12 12" width="12" height="12" aria-hidden="true" fill="currentColor">
          <path fill-rule="evenodd" d="M6 1a5 5 0 1 0 0 10A5 5 0 0 0 6 1zM5.25 4a.75.75 0 0 1 1.5 0v2.25a.75.75 0 0 1-1.5 0V4zm.75 4.5a.75.75 0 1 0 0-1.5.75.75 0 0 0 0 1.5z" clip-rule="evenodd" />
        </svg>
        {@error}
      </p>
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @doc "Form section group (DS-03).
  Groups related <.field> components under a section heading with an optional description."
  def form_section(assigns) do
    ~H"""
    <section class="scoria-form-section" {@rest}>
      <h3 class="scoria-form-section__title">{@title}</h3>
      <p :if={@description} class="scoria-form-section__description">{@description}</p>
      {render_slot(@inner_block)}
    </section>
    """
  end

  # ---------------------------------------------------------------------------
  # DS-05: <.skeleton> and <.toast> — loading/transient feedback (plan 12-04)
  # ---------------------------------------------------------------------------

  attr(:class, :string, default: nil)
  attr(:rows, :integer, default: 1)
  attr(:rest, :global)

  @doc "Loading skeleton placeholder (DS-05).
  Renders stacked skeleton lines with aria-label='Loading…' and role='status'.
  Pulse animation + prefers-reduced-motion suppression are handled by CSS."
  def skeleton(assigns) do
    ~H"""
    <div class="scoria-skeleton-group" aria-label="Loading…" role="status" {@rest}>
      <div :for={_ <- 1..@rows//1} class={["scoria-skeleton", "scoria-skeleton--text", @class]}></div>
    </div>
    """
  end

  attr(:id, :string, required: true)
  attr(:tone, :atom, default: :neutral, values: [:pass, :fail, :warn, :info, :neutral])
  attr(:message, :string, required: true)
  attr(:duration_ms, :integer, default: 4000)

  @doc "Transient toast notification (DS-05).
  Driven by a server @toasts assign. Auto-dismisses via phx-mounted={JS.hide(...)}.
  Manual dismiss X button is also provided. Does NOT use a JS hook (untestable in LiveViewTest).
  The phx-mounted auto-dismiss omits 'to:' so it self-targets the toast div (Pitfall 3);
  the dismiss button MUST target the toast by id (to: '#id') — a bare JS.hide there would
  hide the button, not the toast."
  def toast(assigns) do
    ~H"""
    <div
      id={@id}
      class={["scoria-toast", "scoria-toast--#{@tone}"]}
      role="status"
      phx-mounted={JS.hide(transition: {"scoria-fade", "opacity-100", "opacity-0"}, time: @duration_ms)}
    >
      {toast_icon(@tone)}
      <p>{@message}</p>
      <button
        phx-click={JS.hide(to: "##{@id}", transition: {"scoria-fade", "opacity-100", "opacity-0"}, time: 100)}
        class="scoria-button scoria-button--ghost scoria-button--sm"
        aria-label="Dismiss"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
          <path fill-rule="evenodd" d="M3.72 3.72a.75.75 0 0 1 1.06 0L8 6.94l3.22-3.22a.75.75 0 1 1 1.06 1.06L9.06 8l3.22 3.22a.75.75 0 1 1-1.06 1.06L8 9.06l-3.22 3.22a.75.75 0 0 1-1.06-1.06L6.94 8 3.72 4.78a.75.75 0 0 1 0-1.06z" clip-rule="evenodd" />
        </svg>
      </button>
    </div>
    """
  end

  # 16×16 inline SVG tone icons for toast — status never by color alone (a11y DS-05).
  defp toast_icon(:pass) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm3.78 5.78a.75.75 0 0 0-1.06-1.06L7 9.44 5.28 7.72a.75.75 0 0 0-1.06 1.06l2.25 2.25a.75.75 0 0 0 1.06 0l4.25-4.25z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp toast_icon(:fail) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zM7 5a1 1 0 1 1 2 0v3a1 1 0 1 1-2 0V5zm1 6.25a1.25 1.25 0 1 0 0-2.5 1.25 1.25 0 0 0 0 2.5z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp toast_icon(:warn) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8.22 1.3a.25.25 0 0 0-.44 0L.36 14.26a.25.25 0 0 0 .22.37h14.84a.25.25 0 0 0 .22-.37L8.22 1.3zm-.72 4.7a.5.5 0 0 1 1 0v3a.5.5 0 0 1-1 0V6zm.75 5.5a.75.75 0 1 1-1.5 0 .75.75 0 0 1 1.5 0z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp toast_icon(:info) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 3a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm-1 4a1 1 0 0 1 1-1h.01a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V8z" clip-rule="evenodd" />
    </svg>
    """
  end

  defp toast_icon(_tone) do
    assigns = %{}

    ~H"""
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
      <path fill-rule="evenodd" d="M8 1a7 7 0 1 0 0 14A7 7 0 0 0 8 1zm0 3a1 1 0 1 1 0 2 1 1 0 0 1 0-2zm-1 4a1 1 0 0 1 1-1h.01a1 1 0 0 1 1 1v3a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V8z" clip-rule="evenodd" />
    </svg>
    """
  end

  # ---------------------------------------------------------------------------
  # DS-04: <.notebook> and <.raw_evidence> — unified evidence panel shell (plan 12-04)
  # ---------------------------------------------------------------------------

  attr(:id, :string, required: true)
  attr(:title, :string, required: true)
  attr(:eyebrow, :string, default: nil)
  attr(:empty, :boolean, default: false)
  attr(:selected_tab, :string, default: nil)
  attr(:on_tab_change, :string, default: nil)
  attr(:rest, :global)

  slot :tab, doc: "One tab panel" do
    attr(:key, :string, required: true)
    attr(:label, :string, required: true)
  end

  slot(:empty_slot)

  @doc "Unified tabbed evidence panel shell (DS-04).
  Renders a <nav role='tablist'> tab bar with one <button role='tab'> per <:tab> slot.
  The tab matching @selected_tab carries aria-selected='true'. Clicking a tab emits
  phx-click={@on_tab_change} phx-value-tab={key}. When @empty is true, the :empty_slot
  body is rendered instead of the tab bar and panel."
  def notebook(assigns) do
    # WR-05: a notebook with more than one tab but no on_tab_change handler would
    # render multiple inert (phx-click=nil) controls that look clickable but cannot
    # switch panels. Fail loudly at render rather than ship a silently-broken control.
    if length(assigns.tab) > 1 and is_nil(assigns.on_tab_change) do
      raise ArgumentError,
            "<.notebook> with more than one tab requires on_tab_change; " <>
              "got #{length(assigns.tab)} tabs and on_tab_change=nil"
    end

    # WR-04: select the first tab whenever selected_tab is nil OR points at a key
    # that no current <:tab> exposes (stale value after the tab set changed, or a
    # typo). Without this the tablist renders with every tab aria-selected=false and
    # the panel comprehension yields nothing, so the tabpanel body silently vanishes.
    assigns =
      if assigns.tab != [] and not Enum.any?(assigns.tab, &(&1.key == assigns.selected_tab)) do
        assign(assigns, :selected_tab, hd(assigns.tab).key)
      else
        assigns
      end

    ~H"""
    <div id={@id} class="scoria-notebook" {@rest}>
      <div class="scoria-notebook__header">
        <p :if={@eyebrow} class="scoria-eyebrow">{@eyebrow}</p>
        <h2 class="scoria-notebook__title">{@title}</h2>
      </div>
      <%= if @empty do %>
        <div class="scoria-notebook__panel">
          {render_slot(@empty_slot)}
        </div>
      <% else %>
        <nav class="scoria-notebook__tabbar" role="tablist">
          <%= for tab <- @tab do %>
            <%= if @on_tab_change do %>
              <button
                role="tab"
                id={"#{@id}-tab-#{tab.key}"}
                aria-selected={to_string(tab.key == @selected_tab)}
                class={["scoria-notebook__tab", tab.key == @selected_tab && "scoria-notebook__tab--active"]}
                phx-click={@on_tab_change}
                phx-value-tab={tab.key}
              >
                {tab.label}
              </button>
            <% else %>
              <%!-- WR-05: no on_tab_change handler (single-tab notebook); render a
                    non-interactive span so the control does not present as a clickable
                    button that is actually inert. --%>
              <span
                role="tab"
                id={"#{@id}-tab-#{tab.key}"}
                aria-selected={to_string(tab.key == @selected_tab)}
                class={["scoria-notebook__tab", tab.key == @selected_tab && "scoria-notebook__tab--active"]}
              >
                {tab.label}
              </span>
            <% end %>
          <% end %>
        </nav>
        <%= for tab <- @tab, tab.key == @selected_tab do %>
          <div
            role="tabpanel"
            class="scoria-notebook__panel"
            aria-labelledby={"#{@id}-tab-#{tab.key}"}
          >
            {render_slot(tab)}
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr(:label, :string, default: "Advanced raw evidence")
  attr(:value, :string, default: nil)
  attr(:open, :boolean, default: false)
  attr(:copyable, :boolean, default: false)
  attr(:copy_label, :string, default: "Copy raw evidence")
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block)

  @doc "Raw evidence details/pre block (DS-04).
  Renders a <details>/<summary> with a <pre> code block. Background and font
  tokens are applied via CSS class — not overridden in HEEx."
  def raw_evidence(assigns) do
    ~H"""
    <details
      class={["scoria-raw-evidence", @copyable && "scoria-raw-evidence--copyable", @class]}
      open={@open}
      {@rest}
    >
      <summary class="scoria-raw-evidence__summary">{@label}</summary>
      <.icon_button
        :if={@copyable}
        size={:sm}
        class="scoria-raw-evidence__copy"
        data-raw-evidence-copy
        aria-label={@copy_label}
        title={@copy_label}
      >
        <span class="scoria-raw-evidence__copy-icons" aria-hidden="true">
          <svg
            class="scoria-raw-evidence__copy-icon scoria-raw-evidence__copy-icon--copy"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 16 16"
            width="16"
            height="16"
            fill="currentColor"
          >
            <path d="M4.75 2A1.75 1.75 0 0 0 3 3.75v7.5C3 12.216 3.784 13 4.75 13h6.5A1.75 1.75 0 0 0 13 11.25v-7.5A1.75 1.75 0 0 0 11.25 2h-6.5Zm-.25 1.75a.25.25 0 0 1 .25-.25h6.5a.25.25 0 0 1 .25.25v7.5a.25.25 0 0 1-.25.25h-6.5a.25.25 0 0 1-.25-.25v-7.5Z" />
            <path d="M2 5.75A.75.75 0 0 0 .5 5.75v6.5A3.25 3.25 0 0 0 3.75 15h5.5a.75.75 0 0 0 0-1.5h-5.5A1.75 1.75 0 0 1 2 11.75v-6Z" />
          </svg>
          <svg
            class="scoria-raw-evidence__copy-icon scoria-raw-evidence__copy-icon--check"
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 16 16"
            width="16"
            height="16"
            fill="currentColor"
          >
            <path fill-rule="evenodd" d="M13.78 4.22a.75.75 0 0 1 0 1.06l-6.25 6.25a.75.75 0 0 1-1.06 0L3.22 8.28a.75.75 0 1 1 1.06-1.06L7 9.94l5.72-5.72a.75.75 0 0 1 1.06 0Z" clip-rule="evenodd" />
          </svg>
        </span>
        <span class="sr-only" data-raw-evidence-copy-status aria-live="polite">{@copy_label}</span>
      </.icon_button>
      <pre class="scoria-raw-evidence__pre"><%= @value || render_slot(@inner_block) %></pre>
    </details>
    """
  end

  attr(:title, :string, required: true)
  attr(:description, :string, default: nil)

  attr(:tone, :atom,
    default: :neutral,
    values: [:pass, :info, :warn, :fail, :trace, :brand, :neutral]
  )

  attr(:badge, :string, default: nil)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:actions)
  slot(:inner_block, required: true)

  @doc "Notebook-scoped evidence section with optional status badge and action slot.
Used inside `<.notebook>` `:tab` slot panels to group a titled block of
evidence content. Attrs: `title` (section heading), `description` (optional
supporting copy), `tone` (semantic tone atom for the badge color),
`badge` (optional badge label — rendered only when present).
Slots: `:actions` for action buttons rendered in the section header;
`:inner_block` (required) for evidence rows and action rows."
  def evidence_section(assigns) do
    ~H"""
    <section class={["scoria-evidence-section", @class]} {@rest}>
      <div class="scoria-evidence-section__header">
        <div class="scoria-evidence-section__heading">
          <div class="scoria-evidence-section__title-row">
            <h3 class="scoria-evidence-section__title">{@title}</h3>
            <.badge :if={@badge} tone={@tone} label={@badge} />
          </div>
          <p :if={@description} class="scoria-evidence-section__description">{@description}</p>
        </div>
        <div :if={@actions != []} class="scoria-evidence-section__actions">
          {render_slot(@actions)}
        </div>
      </div>
      <div class="scoria-evidence-section__body">
        {render_slot(@inner_block)}
      </div>
    </section>
    """
  end

  attr(:rows, :list, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)

  @doc "Stable key-value evidence rows for adapter-projected values.
Renders a `<dl>` of `<dt>/<dd>` pairs. The `:rows` attr accepts a list of
either `%{label: _, value: _}` maps or `{label, value}` two-tuples — both
forms are normalized by `normalize_evidence_rows/1` before rendering.
Use inside `<.evidence_section>` `:inner_block` for structured label-value
evidence data (e.g. model name, token count, latency)."
  def evidence_rows(assigns) do
    assigns = assign(assigns, :normalized_rows, normalize_evidence_rows(assigns.rows))

    ~H"""
    <dl class={["scoria-evidence-rows", @class]} {@rest}>
      <div :for={row <- @normalized_rows} class="scoria-evidence-row">
        <dt class="scoria-evidence-row__label">{row.label}</dt>
        <dd class="scoria-evidence-row__value">{row.value}</dd>
      </div>
    </dl>
    """
  end

  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @doc "Compact evidence action/link row. Callers own the action/link semantics.
Used for per-section action links in evidence panels (e.g. \"View trace\",
\"Open replay\", \"Go to approval\"). Renders `:inner_block` inside a flex
container with consistent action-row spacing — place `<a>` or `<.button>`
elements inside."
  def evidence_action_row(assigns) do
    ~H"""
    <div class={["scoria-evidence-action-row", @class]} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr(:title, :string, required: true)
  attr(:class, :string, default: nil)
  attr(:rest, :global)
  slot(:inner_block, required: true)

  @doc "Notebook-scoped evidence empty state. Used for empty `:tab` slot panels
in `<.notebook>` when no evidence data is available for a section. The
`:title` attr is required and names what is absent (e.g. \"No approvals\",
\"No connector invocations\"). Optional `:inner_block` can provide
supplementary copy or a link."
  def evidence_empty(assigns) do
    ~H"""
    <div class={["scoria-evidence-empty", @class]} {@rest}>
      <p class="scoria-evidence-empty__title">{@title}</p>
      <div class="scoria-evidence-empty__body">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  # ---------------------------------------------------------------------------
  # DS-01: <.table> — sortable operator scan table (plan 12-02)
  # ---------------------------------------------------------------------------

  slot :col, doc: "Table column" do
    attr(:label, :string, required: true)
    attr(:key, :atom)
    attr(:class, :string)
  end

  slot(:empty)
  slot(:action)
  slot(:filter)

  slot :mobile_summary,
    doc: "Opt-in per-row mobile summary rendered in a sibling container hidden at >=768px.
  Exposes object label, status badge text, one key scalar/time, and a primary action.
  When absent, the table keeps honest overflow at all widths." do
  end

  attr(:rows, :list, required: true)
  attr(:sort_by, :any, default: nil)
  attr(:sort_dir, :atom, default: :asc, values: [:asc, :desc])
  attr(:id, :string, required: true)
  attr(:page, :integer, default: 1)
  attr(:total_pages, :integer, default: 1)
  attr(:on_sort, :string, default: nil)
  attr(:on_page_change, :string, default: nil)
  attr(:rest, :global)

  @doc "Sortable, paginated operator scan table (DS-01).
  Renders column headers from typed <:col> slots; emits sort events for keyed columns only
  when on_sort is supplied by the parent LiveView.
  Uses the canonical compact scan density from the design system. Falls back to a default empty
  state when rows is empty (overridable via <:empty>). Pagination strip shown when total_pages > 1."
  def table(assigns) do
    # WR-05: a paginated table with no on_page_change handler would render inert
    # phx-click={nil} prev/next controls (a silent no-op). Fail loudly at render
    # instead, matching the <.notebook> on_tab_change guard.
    if assigns.total_pages > 1 and is_nil(assigns.on_page_change) do
      raise ArgumentError,
            "<.table> with total_pages > 1 requires on_page_change; " <>
              "got total_pages=#{assigns.total_pages} and on_page_change=nil"
    end

    ~H"""
    <div class={["scoria-table-shell", @mobile_summary != [] && "scoria-table-shell--has-summary"]}>
      <div :if={@filter != []} class="scoria-table__filter">
        {render_slot(@filter)}
      </div>
      <%!-- Overflow viewport: keyboard-reachable horizontal scroll container (D-13).
           sticky thead still works inside overflow-x: auto (vertical sticky is unaffected). --%>
      <div class="scoria-table__viewport" tabindex="0">
        <table class="scoria-table" id={@id} {@rest}>
          <thead>
            <tr>
              <th
                :for={column <- @col}
                class={["scoria-table__th", Map.get(column, :class)]}
                phx-click={@on_sort && Map.get(column, :key) && @on_sort}
                phx-value-by={@on_sort && Map.get(column, :key)}
                aria-sort={
                  if @on_sort && Map.get(column, :key) != nil do
                    if @sort_by == Map.get(column, :key) do
                      if @sort_dir == :desc, do: "descending", else: "ascending"
                    else
                      "none"
                    end
                  end
                }
              >
                {column.label}
                <svg
                  :if={@on_sort && Map.get(column, :key) != nil}
                  xmlns="http://www.w3.org/2000/svg"
                  viewBox="0 0 16 16"
                  width="16"
                  height="16"
                  aria-hidden="true"
                  fill="currentColor"
                  style={
                    if @sort_by == Map.get(column, :key),
                      do: "color: var(--scoria-action)",
                      else: "color: var(--scoria-text-subtle)"
                  }
                >
                  <path
                    :if={@sort_by == Map.get(column, :key) and @sort_dir == :desc}
                    fill-rule="evenodd"
                    d="M8 4.25a.75.75 0 0 1 .75.75v6.19l1.47-1.47a.75.75 0 1 1 1.06 1.06l-2.75 2.75a.75.75 0 0 1-1.06 0L4.72 11.28a.75.75 0 1 1 1.06-1.06L7.25 11.19V5a.75.75 0 0 1 .75-.75z"
                    clip-rule="evenodd"
                  />
                  <path
                    :if={not (@sort_by == Map.get(column, :key) and @sort_dir == :desc)}
                    fill-rule="evenodd"
                    d="M8 11.75a.75.75 0 0 1-.75-.75V4.81L5.78 6.28a.75.75 0 1 1-1.06-1.06l2.75-2.75a.75.75 0 0 1 1.06 0l2.75 2.75a.75.75 0 1 1-1.06 1.06L8.75 4.81V11a.75.75 0 0 1-.75.75z"
                    clip-rule="evenodd"
                  />
                </svg>
              </th>
              <th :if={@action != []} class="scoria-table__th scoria-table__th--actions"></th>
            </tr>
          </thead>
          <tbody>
            <tr :if={@rows == []}>
              <td colspan={length(@col) + if(@action != [], do: 1, else: 0)}>
                <%= if @empty != [] do %>
                  {render_slot(@empty)}
                <% else %>
                  <.empty_state title="No records found">
                    Adjust your filters or check back when data is available.
                  </.empty_state>
                <% end %>
              </td>
            </tr>
            <tr :for={row <- @rows}>
              <td :for={column <- @col} class={Map.get(column, :class)}>{render_slot(column, row)}</td>
              <td :if={@action != []} class="scoria-table__td--actions">{render_slot(@action, row)}</td>
            </tr>
          </tbody>
        </table>
      </div>
      <%!-- Opt-in per-row mobile summaries (D-08/D-10). Rendered only when the
           :mobile_summary slot is supplied. Hidden at >=768px via CSS; the viewport
           above is hidden below md on tables with summaries (scoria-table-shell--has-summary).
           Content comes from caller's slot — do not hardcode fields here. --%>
      <div :if={@mobile_summary != []} class="scoria-table__mobile-summaries">
        <div :for={row <- @rows}>
          {render_slot(@mobile_summary, row)}
        </div>
      </div>
      <nav :if={@total_pages > 1} aria-label="Pagination" class="scoria-table__pagination">
        <button
          class="scoria-button scoria-button--ghost scoria-button--sm"
          phx-click={@on_page_change}
          phx-value-page={@page - 1}
          disabled={@page <= 1}
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
            <path fill-rule="evenodd" d="M9.78 3.22a.75.75 0 0 0-1.06 0L4.47 7.47a.75.75 0 0 0 0 1.06l4.25 4.25a.75.75 0 0 0 1.06-1.06L6.06 8l3.72-3.72a.75.75 0 0 0 0-1.06z" clip-rule="evenodd" />
          </svg>
        </button>
        <span class="scoria-table__page-label">Page {@page} of {@total_pages}</span>
        <button
          class="scoria-button scoria-button--ghost scoria-button--sm"
          phx-click={@on_page_change}
          phx-value-page={@page + 1}
          disabled={@page >= @total_pages}
        >
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" width="16" height="16" aria-hidden="true" fill="currentColor">
            <path fill-rule="evenodd" d="M6.22 3.22a.75.75 0 0 1 1.06 0l4.25 4.25a.75.75 0 0 1 0 1.06l-4.25 4.25a.75.75 0 0 1-1.06-1.06L9.94 8 6.22 4.28a.75.75 0 0 1 0-1.06z" clip-rule="evenodd" />
          </svg>
        </button>
      </nav>
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

  defp middle_truncate(value) when is_binary(value) do
    if String.length(value) > 15 do
      String.slice(value, 0, 8) <> "..." <> String.slice(value, -3, 3)
    else
      value
    end
  end

  defp middle_truncate(value), do: to_string(value)

  defp origin_label(%{noun: noun, id: id}) when is_binary(noun) and is_binary(id) do
    "← Back to #{noun} #{id}"
  end

  defp origin_label(_origin), do: nil

  defp normalize_evidence_rows(rows) do
    Enum.map(rows, fn
      {label, value} ->
        %{label: evidence_text(label), value: evidence_text(value)}

      row when is_map(row) ->
        %{
          label: evidence_text(Map.get(row, :label) || Map.get(row, "label")),
          value: evidence_text(Map.get(row, :value) || Map.get(row, "value"))
        }

      value ->
        %{label: "", value: evidence_text(value)}
    end)
  end

  defp evidence_text(nil), do: "Not recorded"
  defp evidence_text(value) when is_binary(value), do: value
  defp evidence_text(value) when is_atom(value), do: status_label(value)
  defp evidence_text(value) when is_integer(value) or is_float(value), do: to_string(value)
  defp evidence_text(value), do: inspect(value)

  defp first_command_id(sections) do
    sections
    |> Enum.flat_map(&Map.get(&1, :rows, []))
    |> List.first()
    |> case do
      nil -> nil
      row -> command_row_id(row)
    end
  end

  defp command_row_id(row),
    do: Map.get(row, :id) || "command-#{:erlang.phash2(command_row_label(row))}"

  defp command_row_label(row), do: Map.fetch!(row, :label)
  defp command_row_path(row), do: Map.get(row, :path)
  defp command_row_kbd(row), do: Map.get(row, :kbd)

  defp command_row_search(row) do
    aliases = row |> Map.get(:aliases, []) |> Enum.join(" ")
    [command_row_label(row), aliases] |> Enum.reject(&(&1 in [nil, ""])) |> Enum.join(" ")
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
