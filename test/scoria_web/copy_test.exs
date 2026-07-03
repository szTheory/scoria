defmodule ScoriaWeb.CopyTest do
  use ExUnit.Case, async: true

  alias ScoriaWeb.Copy

  @banned_words ["magic", "seamless", "nothing here"]

  describe "action verbs" do
    test "resolves the D-25 canonical action-verb set" do
      assert Copy.action_verb(:approve) == "Approve"
      assert Copy.action_verb(:deny) == "Deny"
      assert Copy.action_verb(:promote) == "Promote"
      assert Copy.action_verb(:add_manually) == "Add manually"
      assert Copy.action_verb(:resolve) == "Resolve"
      assert Copy.action_verb(:open) == "Open"
      assert Copy.action_verb(:select) == "Select"
      assert Copy.action_verb(:review) == "Review"
      assert Copy.action_verb(:dismiss) == "Dismiss"
      assert Copy.action_verb(:grant) == "Grant"
      assert Copy.action_verb(:revoke) == "Revoke"
      assert Copy.action_verb(:open_trace) == "Open trace"
      assert Copy.action_verb(:retry) == "Retry"
      assert Copy.action_verb(:pin) == "Pin"
      assert Copy.action_verb(:compare) == "Compare"
      assert Copy.action_verb(:edit) == "Edit"
      assert Copy.action_verb(:run) == "Run"
    end

    test "falls back to a humanized string for an unrecognized verb key" do
      assert Copy.action_verb(:archive_forever) == "Archive forever"
    end
  end

  describe "status_label/1" do
    test "resolves the D-25 canonical status vocabulary from a string" do
      assert Copy.status_label("pending") == "Pending"
      assert Copy.status_label("approved") == "Approved"
      assert Copy.status_label("expired") == "Expired"
      assert Copy.status_label("passed") == "Passed"
      assert Copy.status_label("failed") == "Failed"
      assert Copy.status_label("regressed") == "Regressed"
      assert Copy.status_label("running") == "Running"
      assert Copy.status_label("promoted") == "Promoted"
      assert Copy.status_label("draft") == "Draft"
      assert Copy.status_label("published") == "Published"
      assert Copy.status_label("connected") == "Connected"
      assert Copy.status_label("disconnected") == "Disconnected"
      assert Copy.status_label("idle") == "Idle"
    end

    test "resolves an atom the same as its string equivalent" do
      assert Copy.status_label(:pending) == Copy.status_label("pending")
    end

    test "never curates rejected -> Denied (approval-domain only, D-24d)" do
      refute Copy.status_label("rejected") == "Denied"
    end

    test "falls back to a humanized generic transform for an unseen status" do
      assert Copy.status_label("waiting_for_input") == "Waiting for input"
    end

    test "never raises on nil or unexpected input" do
      assert Copy.status_label(nil) == "Unknown"
    end
  end

  describe "empty_title/1, empty_cta/1, error_line/1, loading_label/1" do
    test "every domain getter returns a binary" do
      domains = [:incidents, :datasets, :reviews, :connectors, :approvals, :runs, :evals, :unknown_domain]

      for domain <- domains do
        assert is_binary(Copy.empty_title(domain))
        assert is_binary(Copy.empty_cta(domain))
        assert is_binary(Copy.loading_label(domain))
      end

      for reason <- [:connection, :not_found, :stale, :unauthorized, :unknown_reason] do
        assert is_binary(Copy.error_line(reason))
      end
    end

    test "empty_title/1 and empty_cta/1 give the eval domain the canonical brand-book example" do
      assert Copy.empty_title(:evals) == "No eval datasets yet"
      assert Copy.empty_cta(:evals) == "Promote a production trace to start a regression suite."
    end
  end

  describe "banned words" do
    test "no public getter emits a banned word" do
      all_strings =
        Enum.map([:approve, :deny, :promote, :run], &Copy.action_verb/1) ++
          Enum.map(~w(pending approved expired passed failed regressed running promoted draft published connected disconnected idle), &Copy.status_label/1) ++
          Enum.flat_map([:incidents, :datasets, :reviews, :connectors, :approvals, :runs, :evals, :unknown_domain], fn domain ->
            [Copy.empty_title(domain), Copy.empty_cta(domain), Copy.loading_label(domain)]
          end) ++
          Enum.map([:connection, :not_found, :stale, :unauthorized, :unknown_reason], &Copy.error_line/1)

      for string <- all_strings, banned <- @banned_words do
        refute String.downcase(string) =~ banned,
               "expected #{inspect(string)} not to contain banned word #{inspect(banned)}"
      end
    end
  end

  describe "module discipline" do
    test "Copy module source contains zero ~H sigils" do
      source = File.read!(Path.join([File.cwd!(), "lib", "scoria_web", "copy.ex"]))
      refute source =~ ~r/~H"""/
    end
  end
end
