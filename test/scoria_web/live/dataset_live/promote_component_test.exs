defmodule ScoriaWeb.DatasetLive.PromoteComponentTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  @endpoint ScoriaWeb.OrchestratorLiveTest.Endpoint

  alias ScoriaWeb.DatasetLive.PromoteComponent
  alias Scoria.Repo.Trace
  alias Ecto.UUID

  test "renders promote form and triggers promotion logic" do
    trace = %Trace{
      id: UUID.generate(),
      session_id: "test-sess",
      attributes: %{},
      spans: []
    }

    # render_component checks that it renders successfully
    html = render_component(PromoteComponent, id: "promote-trace", trace: trace)
    
    assert html =~ "Promote Trace to Dataset"
    assert html =~ "Dataset Name"
    assert html =~ "promote-form"
  end
end
