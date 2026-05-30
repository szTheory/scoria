defmodule Scoria.Observe.RedactorTest do
  use ExUnit.Case, async: false

  alias Scoria.Observe.Redactor

  test "redacts default keys" do
    assert Redactor.redact(%{"password" => "secret", "name" => "jon"}) == %{"password" => "[REDACTED]", "name" => "jon"}
    assert Redactor.redact(%{api_key: "123", email: "a@b.c"}) == %{api_key: "[REDACTED]", email: "a@b.c"}
  end

  test "redacts nested maps and lists" do
    input = %{
      "user" => %{
        "token" => "abc",
        "nested" => [
          %{"secret" => "hidden", "public" => "visible"},
          "just a string"
        ]
      }
    }

    expected = %{
      "user" => %{
        "token" => "[REDACTED]",
        "nested" => [
          %{"secret" => "[REDACTED]", "public" => "visible"},
          "just a string"
        ]
      }
    }

    assert Redactor.redact(input) == expected
  end

  test "does not match partial keys like llm.token_count" do
    assert Redactor.redact(%{"llm.token_count" => 10, "token" => "abc"}) == %{"llm.token_count" => 10, "token" => "[REDACTED]"}
  end

  test "uses application config for deny list" do
    Application.put_env(:scoria, Scoria.Observe.Redactor, deny_list: ["custom_secret", :custom_atom_secret])
    on_exit(fn -> Application.delete_env(:scoria, Scoria.Observe.Redactor) end)

    assert Redactor.redact(%{"custom_secret" => "123", "password" => "456", custom_atom_secret: "789"}) ==
      %{"custom_secret" => "[REDACTED]", "password" => "[REDACTED]", custom_atom_secret: "[REDACTED]"}
  end

  test "scrubs deny-list key=value patterns from text" do
    assert Redactor.scrub_text("leak api_key=super-secret-key") ==
             "leak api_key=[REDACTED]"
  end

  test "defers to MFA override if configured" do
    Application.put_env(:scoria, Scoria.Observe.Redactor, mfa: {__MODULE__, :custom_redact, []})
    on_exit(fn -> Application.delete_env(:scoria, Scoria.Observe.Redactor) end)

    assert Redactor.redact(%{"password" => "secret"}) == :custom_mfa_called
  end

  def custom_redact(_data) do
    :custom_mfa_called
  end
end