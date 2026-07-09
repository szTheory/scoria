defmodule Scoria.VerificationLanes do
  @moduledoc """
  Legacy 0.1.x compatibility wrapper for `Scoria.VerificationSuites`.

  Use `Scoria.VerificationSuites` for final public proof-command vocabulary.
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
