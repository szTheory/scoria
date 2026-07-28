defmodule Scoria.MCP.ClassificationTest do
  use ExUnit.Case, async: false

  alias Scoria.MCP.Classification
  alias Scoria.MCP.Executor

  # `:persistent_term` and telemetry handlers are global -- this suite must
  # not run concurrently with itself or other suites poking the same
  # `Scoria.MCP.TaskSupervisor`.

  defmodule DeclaringTool do
    use Scoria.MCP.Tool, reads_private_data: true, can_exfiltrate: true, action_class: "exec"

    @impl true
    def name, do: "declaring_tool"

    @impl true
    def description, do: "Declares its own classification via the use macro"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context), do: {:ok, %{context: context}}
  end

  defmodule BareUseTool do
    use Scoria.MCP.Tool

    @impl true
    def name, do: "bare_use_tool"

    @impl true
    def description, do: "Bare `use Scoria.MCP.Tool` with no opts"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{}}
  end

  defmodule UndeclaredTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "undeclared_tool"

    @impl true
    def description, do: "Implements only the four required callbacks"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, context), do: {:ok, %{context: context}}
  end

  defmodule RaisingClassificationTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "raising_classification_tool"

    @impl true
    def description, do: "classification/0 raises"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{}}

    @impl true
    def classification, do: raise("boom")
  end

  defmodule HangingClassificationTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "hanging_classification_tool"

    @impl true
    def description, do: "classification/0 sleeps past the isolation bound"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{}}

    @impl true
    def classification do
      Process.sleep(500)
      Classification.declared(action_class: "read")
    end
  end

  defmodule JunkReturnTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "junk_return_tool"

    @impl true
    def description, do: "classification/0 returns a non-struct"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{}}

    @impl true
    def classification, do: :not_a_classification_struct
  end

  defmodule JunkFieldsTool do
    @behaviour Scoria.MCP.Tool

    @impl true
    def name, do: "junk_fields_tool"

    @impl true
    def description, do: "classification/0 returns a struct with junk fields"

    @impl true
    def input_schema, do: %{}

    @impl true
    def execute(_args, _context), do: {:ok, %{}}

    @impl true
    def classification do
      %Classification{
        reads_private_data: "yes",
        sees_untrusted_content: nil,
        can_exfiltrate: 1,
        action_class: "banana",
        source: :unclassified_default
      }
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Scoria.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Scoria.Repo, {:shared, self()})

    Classification.reset_memo()
    on_exit(fn -> Application.delete_env(:scoria, Classification) end)
    :ok
  end

  describe "action_classes/0" do
    test "returns the closed enum in load-bearing order" do
      assert Classification.action_classes() == ["read", "write", "exec", "admin"]
      assert Enum.at(Classification.action_classes(), 0) == "read"
    end
  end

  describe "default_action_class/0 and sources/0" do
    test "default_action_class/0 is the maximally-gated member" do
      assert Classification.default_action_class() == "admin"
    end

    test "sources/0 is the closed three-member set" do
      assert Classification.sources() == [:tool_declared, :host_tightened, :unclassified_default]
    end
  end

  describe "normalize_action_class/1" do
    test "passes through an exact-match member" do
      assert Classification.normalize_action_class("write") == "write"
    end

    test "fails closed on mismatched case, atoms, nil, empty, and junk" do
      for bad <- ["Write", :write, nil, "", "nonsense"] do
        assert Classification.normalize_action_class(bad) == "admin"
      end
    end
  end

  describe "unclassified_default/0" do
    test "is maximally gated" do
      assert %Classification{
               reads_private_data: true,
               sees_untrusted_content: true,
               can_exfiltrate: true,
               action_class: "admin",
               source: :unclassified_default
             } = Classification.unclassified_default()
    end
  end

  describe "@enforce_keys [:source]" do
    test "building without :source raises" do
      assert_raise ArgumentError, fn ->
        Code.eval_string("%Scoria.MCP.Classification{action_class: \"read\"}")
      end
    end
  end

  describe "declared/1 and the use macro" do
    test "explicit opts produce the declared shape" do
      assert %Classification{
               reads_private_data: true,
               sees_untrusted_content: false,
               can_exfiltrate: true,
               action_class: "exec",
               source: :tool_declared
             } = DeclaringTool.classification()
    end

    test "bare use defaults conservatively (D-A3)" do
      assert %Classification{
               reads_private_data: false,
               sees_untrusted_content: false,
               can_exfiltrate: false,
               action_class: "read",
               source: :tool_declared
             } = BareUseTool.classification()
    end
  end

  describe "tool_declaration/1" do
    test "a module with only the four required callbacks resolves to :none" do
      assert Classification.tool_declaration(UndeclaredTool) == :none
    end

    test "a module using the macro resolves to {:ok, declared}" do
      assert {:ok, %Classification{source: :tool_declared, action_class: "exec"}} =
               Classification.tool_declaration(DeclaringTool)
    end

    test "a raising classification/0 fails closed to :none and does not harm the caller" do
      assert Classification.tool_declaration(RaisingClassificationTool) == :none
    end

    test "a classification/0 that hangs past the bound fails closed to :none" do
      Application.put_env(:scoria, Classification, isolation_timeout_ms: 20)

      assert Classification.tool_declaration(HangingClassificationTool) == :none
    end

    test "a non-struct return normalizes fail-closed to a maximal tool_declared struct (D-A4)" do
      assert {:ok,
              %Classification{
                reads_private_data: true,
                sees_untrusted_content: true,
                can_exfiltrate: true,
                action_class: "admin",
                source: :tool_declared
              }} = Classification.tool_declaration(JunkReturnTool)
    end

    test "a struct with junk fields normalizes fail-closed and forces source: :tool_declared (D-A4)" do
      assert {:ok,
              %Classification{
                reads_private_data: true,
                sees_untrusted_content: true,
                can_exfiltrate: true,
                action_class: "admin",
                source: :tool_declared
              }} = Classification.tool_declaration(JunkFieldsTool)
    end

    test "resolution is memoized per module" do
      assert {:ok, first} = Classification.tool_declaration(DeclaringTool)
      assert {:ok, second} = Classification.tool_declaration(DeclaringTool)
      assert first == second
    end
  end

  describe "Executor.execute/4 end-to-end resolution (D-05, site 1)" do
    setup do
      parent = self()
      ref = make_ref()

      handler = fn event_name, measurements, metadata, _config ->
        send(parent, {:telemetry_event, ref, event_name, measurements, metadata})
      end

      handler_id = "classification-test-#{System.unique_integer()}"
      :telemetry.attach(handler_id, [:scoria, :class, :unclassified], handler, nil)
      on_exit(fn -> :telemetry.detach(handler_id) end)

      %{ref: ref}
    end

    test "an undeclared tool still runs and emits exactly one unclassified event", %{ref: ref} do
      assert {:ok, %{context: context}} =
               Executor.execute(UndeclaredTool, %{}, %{actor_id: "user-1", tenant_id: "tenant-1"})

      assert %Classification{source: :unclassified_default, action_class: "admin"} =
               Map.get(context, :tool_classification)

      assert_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements, metadata}
      assert metadata.site == :mcp_executor
      assert metadata.tool == UndeclaredTool

      refute_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements, _metadata2}
    end

    test "a declaring tool emits no unclassified event and carries its declaration on the context" do
      handler_id = "classification-test-declaring-#{System.unique_integer()}"
      parent = self()
      ref = make_ref()

      :telemetry.attach(
        handler_id,
        [:scoria, :class, :unclassified],
        fn event_name, measurements, metadata, _config ->
          send(parent, {:telemetry_event, ref, event_name, measurements, metadata})
        end,
        nil
      )

      on_exit(fn -> :telemetry.detach(handler_id) end)

      assert {:ok, %{context: context}} =
               Executor.execute(DeclaringTool, %{}, %{actor_id: "user-1", tenant_id: "tenant-1"})

      assert %Classification{source: :tool_declared, action_class: "exec"} =
               Map.get(context, :tool_classification)

      refute_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements, _metadata}
    end

    test "resolution is idempotent: a pre-populated %Classification{} on context is reused and re-emits no telemetry",
         %{ref: ref} do
      preexisting = Classification.declared(action_class: "write")

      assert {:ok, %{context: context}} =
               Executor.execute(UndeclaredTool, %{}, %{tool_classification: preexisting})

      assert Map.get(context, :tool_classification) == preexisting

      refute_receive {:telemetry_event, ^ref, [:scoria, :class, :unclassified], _measurements, _metadata}
    end

    test "the context handed through a replay run carries :tool_classification into build_replay_seam/2's seam" do
      {:ok, run} =
        Scoria.Workflows.create_run(%{
          root_role_id: "executor",
          execution_mode: "replay",
          source_run_id: Ecto.UUID.generate(),
          source_checkpoint_id: Ecto.UUID.generate()
        })

      assert {:ok, %{context: context}} =
               Executor.execute(DeclaringTool, %{}, %{
                 run_id: run.id,
                 local_classification: :pure,
                 tool_id: DeclaringTool.name()
               })

      assert %Classification{source: :tool_declared, action_class: "exec"} =
               Map.get(context, :tool_classification)
    end
  end

end
