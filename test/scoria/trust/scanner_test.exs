defmodule Scoria.Trust.ScannerTest do
  use ExUnit.Case, async: true

  alias Scoria.Trust.Scanner
  alias Scoria.Trust.Scanner.NoOp

  describe "Scoria.Trust.Scanner.NoOp" do
    test "scan/2 always returns {:ok, :not_scanned} for binary content" do
      assert {:ok, :not_scanned} = NoOp.scan("some raw content", %{})
    end

    test "scan/2 always returns {:ok, :not_scanned} for map content" do
      assert {:ok, :not_scanned} = NoOp.scan(%{body: "structured"}, %{})
    end

    test "scan/2 ignores an arbitrary non-empty context" do
      assert {:ok, :not_scanned} = NoOp.scan("content", %{trace_id: "abc", tool_ref: "Foo"})
    end

    test "NoOp implements the Scoria.Trust.Scanner behaviour" do
      assert Scanner in (NoOp.__info__(:attributes)[:behaviour] || [])
    end
  end

  describe "content_scanner registration (D-17)" do
    test "Application.get_env defaults to Scoria.Trust.Scanner.NoOp when unset" do
      assert Application.get_env(:scoria, :content_scanner, NoOp) == NoOp
    end

    test "an explicit app-env value overrides the default" do
      Application.put_env(:scoria, :content_scanner, :some_other_scanner)
      on_exit(fn -> Application.delete_env(:scoria, :content_scanner) end)

      assert Application.get_env(:scoria, :content_scanner, NoOp) == :some_other_scanner
    end
  end

  describe "boot: Scoria.Trust.TaskSupervisor" do
    test "is a live pid after application boot" do
      pid = Process.whereis(Scoria.Trust.TaskSupervisor)
      assert is_pid(pid)
      assert Process.alive?(pid)
    end
  end
end
