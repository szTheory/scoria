defmodule ScoriaWeb.PromptLive.IndexTest.Router do
  use Phoenix.Router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
  end

  scope "/" do
    pipe_through(:browser)
  end
end

defmodule ScoriaWeb.PromptLive.IndexTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria

  plug(Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  )

  plug(ScoriaWeb.PromptLive.IndexTest.Router)
end

defmodule ScoriaWeb.PromptLive.IndexTest do
  use Scoria.EvalCase, async: true
  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.PromptLive.IndexTest.Endpoint

  alias Scoria.PromptRegistry

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.PromptLive.IndexTest.Endpoint,
      secret_key_base:
        "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1MpAdExtraKeyMaterial0123456789",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.PromptLive.IndexTest.Endpoint)
    :ok
  end

  test "renders an empty state when no prompt versions exist" do
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.PromptLive.IndexTest.Endpoint)

    {:ok, _view, html} = live_isolated(conn, ScoriaWeb.PromptLive.Index)

    assert html =~ "Prompt Registry"
    assert html =~ "No prompt versions yet"
    assert html =~ "Prompt versions appear after backed prompt edits are recorded."
    refute html =~ "No prompt templates yet"
  end

  test "renders prompt templates and handles editing and token estimation" do
    entity_id = Ecto.UUID.generate()

    {:ok, template} =
      PromptRegistry.create_draft_template(%{
        entity_id: entity_id,
        system_message: "You are a helpful assistant.",
        user_template: "Translate this: {{text}}"
      })

    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session(%{})
      |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.PromptLive.IndexTest.Endpoint)

    {:ok, view, html} = live_isolated(conn, ScoriaWeb.PromptLive.Index)

    # Initial render should list the template
    assert html =~ "Prompt Registry"
    assert html =~ ~s(id="prompt-versions")
    assert html =~ template.entity_id
    assert html =~ template.system_message
    assert html =~ "Draft"

    # Click edit
    html = render_click(view, "edit", %{"id" => template.id})
    assert html =~ "Edit Template: #{template.entity_id}"

    # Form inputs should calculate tokens dynamically
    # Test phx-change
    html =
      render_change(view, "validate", %{
        "prompt_template" => %{
          "system_message" => "You are a very helpful assistant indeed.",
          "user_template" => "Translate this: {{text}} to {{language}}"
        }
      })

    # Tiktoken estimation for the combined text
    # Let's say it's around 15 tokens. The page should show the estimation.
    assert html =~ "Estimated Tokens:"

    # Submit form
    html =
      render_submit(view, "save", %{
        "prompt_template" => %{
          "system_message" => "You are a very helpful assistant indeed.",
          "user_template" => "Translate this: {{text}} to {{language}}"
        }
      })

    # Form disappears and we see updated list
    refute html =~ "Edit Template:"
    assert html =~ "You are a very helpful assistant indeed."

    # Verify DB has new version or updated draft
    templates = PromptRegistry.list_prompt_templates()
    # It updates the draft in place since status is 'draft'
    updated = Enum.find(templates, fn t -> t.entity_id == entity_id end)
    assert updated.system_message == "You are a very helpful assistant indeed."
    # If the logic upgrades version, it would be version 2, but for draft it's usually 1
    # Actually `update_prompt_template` might create a new version if not draft.
    # The requirement is that we can edit it.
  end
end
