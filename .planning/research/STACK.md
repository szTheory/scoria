# Project Research - Stack

**Milestone:** `v2.2 OSS adopter onramp`
**Date:** 2026-05-25
**Question:** What stack additions or changes are needed to make Scoria publishable, installable, and verifiable as a serious OSS Phoenix dependency?

## Existing Scoria Assets To Reuse

- `mix.exs` now carries `:description`, `:docs`, `:package`, `:source_url`, and `:homepage_url`, which aligns with the official Hex publish metadata expectations for public packages.
- `mix scoria.install` already mounts the router surface, injects runtime defaults, copies core migrations, and tolerates missing Tailwind config in [lib/mix/tasks/scoria.install.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.install.ex:1).
- The repo already exposes bounded proof tasks for the default lane and semantic lane through `mix test.adoption` and `mix test.semantic_fast_path` in [lib/mix/tasks/test.adoption.ex](/Users/jon/projects/scoria/lib/mix/tasks/test.adoption.ex:1) and [lib/mix/tasks/scoria.test.semantic_fast_path.ex](/Users/jon/projects/scoria/lib/mix/tasks/scoria.test.semantic_fast_path.ex:1).
- Operator-facing install and verification docs already exist in [README.md](/Users/jon/projects/scoria/README.md:1), [docs/adoption_lanes.md](/Users/jon/projects/scoria/docs/adoption_lanes.md:1), and [docs/operator_verification.md](/Users/jon/projects/scoria/docs/operator_verification.md:1).

## Recommended Additions

### 1. Add a real documentation build dependency

Scoria now configures `:docs` in `mix.exs`, but the repo does not currently declare `:ex_doc`.

Recommended addition:

- add `{:ex_doc, "~> 0.40", only: :dev, runtime: false}` to `deps/0`

Rationale:

- Hex publishes docs by running `mix docs`, and the official Hex guide recommends building docs locally before publish.
- ExDoc is the standard tool that provides `mix docs` and consumes `:source_url`, `:homepage_url`, `docs: [main: ..., extras: ...]`, and related configuration.

### 2. Add a release-preview lane before first publish

Scoria needs one maintainer-facing lane that validates the package boundary before Hex publication.

Recommended lane:

- `mix hex.build`
- `mix docs`
- a package file-inventory assertion that the shipped tarball includes runtime code, migrations, docs entrypoints, and excludes test-only implementation

Rationale:

- Hex package quality is not only about metadata; the publish step packages a concrete file set.
- The first publish should fail locally if docs do not build or if critical files are omitted from the package surface.

### 3. Add a canonical consumer-app fixture or generated host-app harness

Scoria's install contract is now closer to reality, but the current adoption proof is still mostly repo-internal.

Recommended addition:

- a minimal Phoenix consumer app fixture or generated temporary host app harness that proves:
  - dependency fetch
  - `mix scoria.install`
  - migration copy and `mix ecto.migrate`
  - one runtime flow and operator route visibility

Rationale:

- This closes the difference between "our own repo tests pass" and "a fresh adopter can actually wire this into a normal Phoenix app."

### 4. Keep proof helpers inside Mix-task and test-support boundaries

The milestone should avoid leaking publication or verification internals into the runtime surface.

Recommended module placement:

- Mix tasks under `lib/mix/tasks/`
- consumer harness helpers under `test/support` or `lib/scoria/test_support`
- release-specific assertions in dedicated tests rather than runtime modules

Rationale:

- `Mix.Project` documentation explicitly warns against using Mix project metadata as runtime application configuration.
- Publish and docs concerns belong to build/test seams, not the public Scoria runtime API.

## What Not To Add In This Milestone

- No package split into multiple Hex libraries yet
- No hosted demo environment as a prerequisite for adoption proof
- No semantic-cache backend expansion
- No new runtime feature family just to make the release feel larger
- No support story that depends on undocumented maintainer setup knowledge

## External References

- Hex publish guide: https://hex.pm/docs/publish
- Mix project configuration: https://hexdocs.pm/mix/Mix.Project.html
- ExDoc configuration: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
