# Phase 63 — Pattern Map

**Phase:** 63 — Manifest Check Fingerprint Hardening  
**Generated:** 2026-05-27

## Analog Modules

| Target (new/modified) | Closest analog | Role |
|----------------------|----------------|------|
| Planner manifest metadata | Phase 61 `Contract` + `Report` additive JSON | Extend plan/report without changing check_result |
| `manifest_state` on plan | Phase 60 drift `reason_code` on entries | Evidence field that does not affect classification |
| Operator doc subsection | Phase 61 `docs/operator_verification.md` installer modes block | Single subsection, adoption_surface pins |
| Tampered-manifest test | `install_check_test.exs` trailer matrix | Subprocess fixture + assert exit unchanged |
| Remove dead `put_new` | Phase 59 tri-state contract | Honest code matching documented behavior |

## Code Excerpts

### Dead manifest fingerprint branch (remove)

```elixir
# lib/scoria/install/planner.ex (current — misleading)
|> Map.put_new(:fingerprint, manifest_entry[:fingerprint] || "unavailable")
```

Surface analyzers always set fingerprint first:

```elixir
# lib/scoria/install/surface/router.ex
fingerprint = fingerprint(content)
%{
  classification: ...,
  fingerprint: fingerprint,
  ...
}
```

### Check result (preserve — classification only)

```elixir
# lib/scoria/install/report.ex
defp do_check_result(%{entries: entries}) when is_list(entries) do
  classifications = MapSet.new(Enum.map(entries, & &1.classification))
  cond do
    MapSet.member?(classifications, :manual_review) -> %{status: :manual_review, exit_code: 1}
    ...
  end
end
```

### Apply freshness gate (preserve)

```elixir
# lib/scoria/install/apply_executor.ex
validate_freshness!(plan, project_root)
# Manifest.validate_freshness/2 — plan fingerprint vs live disk
```

### Phase 61 additive JSON pattern

```elixir
# lib/scoria/install/report.ex
|> Map.put(:mode, mode_label(mode))
# Phase 63: add top-level :manifest map in normalize_plan_for_json
```

## File Modification Map

| File | Action | Pattern to follow |
|------|--------|-------------------|
| `lib/scoria/install/planner.ex` | modify | Remove dead merge; add manifest_state; optional manifest_fingerprint |
| `lib/scoria/install/manifest.ex` | extend | `@moduledoc` check vs apply roles |
| `lib/scoria/install/report.ex` | extend | Additive JSON/human manifest metadata |
| `lib/scoria/install/contract.ex` | extend | Manifest metadata key constants |
| `lib/mix/tasks/scoria.install.ex` | extend | `## Apply freshness` in `@moduledoc` |
| `docs/operator_verification.md` | extend | `### Check vs apply drift detection` |
| `docs/adoption_lanes.md` | extend | One-line cross-link |
| `test/scoria/install/report_test.exs` | extend | manifest JSON + human line tests |
| `test/mix/tasks/scoria.install_check_test.exs` | extend | tampered manifest + absent manifest cases |
| `test/scoria/adoption_surface_test.exs` | extend | operator guide phrase pins |
| `test/scoria/install/mode_equivalence_test.exs` | extend | include manifest fields in normalize if needed |

## PATTERN MAPPING COMPLETE
