defmodule Scoria.VerificationLanes do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.VerificationSuites`.

  0.1.x compatibility migration note: new code and docs should use
  `Scoria.VerificationSuites` and the verification suite vocabulary for adopter
  proof commands. This module delegates the old lane-shaped API to the final
  module so existing callers can migrate without a runtime warning.

  Keep this wrapper only for copied 0.1.x code or tests that still name
  verification lanes. See `guides/reference/glossary.md` for the compatibility
  alias map.
  """

  alias Scoria.VerificationSuites

  defdelegate all, to: VerificationSuites
  defdelegate ids, to: VerificationSuites
  defdelegate fetch!(id), to: VerificationSuites
  defdelegate command(id), to: VerificationSuites
  defdelegate ci_command(id), to: VerificationSuites
  defdelegate env(id), to: VerificationSuites
  defdelegate prerequisites(id), to: VerificationSuites
  defdelegate exclusions(id), to: VerificationSuites
  defdelegate closeout_order, to: VerificationSuites
  defdelegate closeout_chain, to: VerificationSuites
  defdelegate boundary_sentence(id), to: VerificationSuites
end
