defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.Router do
  use Phoenix.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
  end

  scope "/" do
    pipe_through :browser
  end
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint do
  use Phoenix.Endpoint, otp_app: :scoria
  plug Plug.Session,
    store: :cookie,
    key: "_scoria_key",
    signing_salt: "scoria_salt"
  plug ScoriaWeb.DatasetLive.PromoteComponentTest.Router
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest.DummyLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, assign(socket, :step, %{projected_context: %{"foo" => "bar"}})}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.live_component module={ScoriaWeb.DatasetLive.PromoteComponent} id="promote-component" step={@step} />
    </div>
    """
  end
end

defmodule ScoriaWeb.DatasetLive.PromoteComponentTest do
  use Scoria.EvalCase, async: true
  import Phoenix.LiveViewTest

  alias Scoria.Eval

  @endpoint ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint

  setup_all do
    Application.put_env(:scoria, ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint,
      secret_key_base: "uR22+c0W1x9N6yT1c8/p/k7j6K/E1lXz+J2M9/z/K6N2e7jW1M9/z/K6N2e7jW1M",
      pubsub_server: Scoria.PubSub,
      live_view: [signing_salt: "112345678"],
      debug_errors: true
    )

    :ok
  end

  setup do
    start_supervised!(ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint)
    :ok
  end

  test "renders input json and can submit to save to dataset" do
    {:ok, dataset} = Eval.create_dataset(%{name: "Test Dataset", version: "1.0"})

    conn = Phoenix.ConnTest.build_conn()
           |> Plug.Test.init_test_session(%{})
           |> Plug.Conn.put_private(:phoenix_endpoint, ScoriaWeb.DatasetLive.PromoteComponentTest.Endpoint)

    {:ok, view, html} = live_isolated(conn, ScoriaWeb.DatasetLive.PromoteComponentTest.DummyLive)

    assert html =~ "Promote to Dataset"
    assert html =~ "&quot;foo&quot;: &quot;bar&quot;"
    assert html =~ "Test Dataset (v1.0)"

    form_data = %{
      "item" => %{
        "dataset_id" => to_string(dataset.id),
        "input" => ~s({"foo": "bar"}),
        "expected_output" => ~s({"result": "success"})
      }
    }

    # Simulate saving via the form
    render_submit(view |> element("form"), form_data)

    # Verify item was added
    items = Eval.list_dataset_items(dataset.id)
    assert length(items) == 1
    
    item = hd(items)
    assert item.input == %{"foo" => "bar"}
    assert item.expected_output == %{"result" => "success"}
  end
end
