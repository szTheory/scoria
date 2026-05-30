# Phase 80 — Pattern Map

**Mapped:** 2026-05-29

## File Roles

| File | Role | Analog |
|------|------|--------|
| `lib/scoria/hex_consumer_contract.ex` | extend | Current unpack cache pattern → baseline fixture |
| `test/support/scoria/host_app_proof/runner.ex` | extend | `run_full_proof!/1` → `run_upgrade_proof!/2` |
| `test/support/scoria/host_app_proof/generator.ex` | extend | `patch_mix_exs!` → `bump_unpack_dep!/2` |
| `test/scoria/host_app_upgrade_proof_test.exs` | **create** | `host_app_consumer_proof_test.exs` |
| `lib/mix/tasks/test.adoption.ex` | modify | Add one line to `@adoption_test_files` |
| `test/mix/tasks/test.adoption_test.exs` | modify | Expected file list guard |
| `test/fixtures/hex_consumer/scoria-0.1.0-unpack/` | **create** | `tmp/scoria-hex-consumer/` cache layout |

## Excerpt: Consumer proof pattern (reuse)

```elixir
# test/scoria/host_app_consumer_proof_test.exs
host = Generator.create_host!(dep_mode: :hex_tarball, unpack_root: unpack_root, cleanup: &on_exit/1)
proof = Runner.run_full_proof!(host)
assert proof.steps == Runner.expected_steps(host)
```

## Excerpt: Install check trailer pins

```elixir
# test/mix/tasks/scoria.install_check_test.exs
assert_check_result(:compliant, 0, "SCORIA_CHECK_RESULT status=compliant exit_code=0")
assert_check_result(:drift, 1, "SCORIA_CHECK_RESULT status=drift exit_code=1")
```

## Excerpt: Adoption file list SSOT

```elixir
# lib/mix/tasks/test.adoption.ex — append after consumer proof line:
"test/scoria/host_app_upgrade_proof_test.exs",
```
