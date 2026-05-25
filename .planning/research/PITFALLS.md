# Project Research - Pitfalls

**Milestone:** `v2.2 OSS adopter onramp`
**Date:** 2026-05-25
**Question:** What are the main risks when turning Scoria's current repo state into a publishable OSS adoption story?

## 1. Treating metadata as release truth when docs still do not build

**Why it happens**

Adding `:description`, `:package`, and `:docs` to `mix.exs` feels like the publish step is "done."

**Why it is dangerous**

Hex publishes docs by running `mix docs`. If `:ex_doc` is missing or docs extras drift, the first real publish attempt fails at the point where trust should be highest.

**Prevention**

- add a real docs-build dependency
- make `mix docs` part of the release-preview lane

## 2. Confusing repo-internal proof with adopter proof

**Why it happens**

The repo already has strong tests and named lanes, so it is easy to assume the install story is closed.

**Why it is dangerous**

Repo tests do not fully prove that a fresh Phoenix host app can adopt Scoria through the public path without maintainer intuition.

**Prevention**

- add a canonical consumer-app fixture or generated host-app harness
- make it prove dependency fetch, install, migrate, route visibility, and one runtime flow

## 3. Letting optional lanes bleed into the default lane

**Why it happens**

Scoria now includes handoffs, semantic caching, and knowledge surfaces, and docs naturally accumulate those capabilities.

**Why it is dangerous**

New adopters lose the boring path. Support truth erodes when the default lane silently depends on optional knowledge or advanced runtime setup.

**Prevention**

- keep default runtime lane docs and proof isolated
- route optional knowledge and semantic fast path to their own named commands

## 4. Installer drift between docs, task output, and real file mutations

**Why it happens**

Installer behavior changes quickly during local hardening, while docs and support copy lag behind.

**Why it is dangerous**

This creates the worst kind of OSS bug: the software works one way, the docs describe another, and maintainers answer a third way from memory.

**Prevention**

- assert installer output and docs source against the same lane vocabulary
- keep one verification guide as the canonical support entrypoint

## 5. Publishing a package with the wrong file inventory

**Why it happens**

Hex defaults are generous, and maintainers often assume required files are included automatically.

**Why it is dangerous**

Missing migrations, guides, or docs inputs can make the first published artifact materially weaker than the repo state that looked correct locally.

**Prevention**

- preview the built package locally
- add tests or assertions around package file inventory for required surfaces

## 6. Pulling package/release concerns into the runtime API

**Why it happens**

Release work touches project metadata, which can tempt code to inspect Mix project state at runtime.

**Why it is dangerous**

Official Mix guidance is to keep Mix project configuration out of runtime application logic. Mixing those layers creates brittle behavior in releases.

**Prevention**

- keep release and docs work inside Mix-task, CI, and test seams
- continue using application config for runtime behavior

## Which Phase Should Address What

- Phase 47: package/docs build closure and release-preview truth
- Phase 48: installer contract plus consumer-app proof
- Phase 49: support-truth alignment and milestone closeout verification

## External References

- Hex publish guide: https://hex.pm/docs/publish
- Mix project configuration: https://hexdocs.pm/mix/Mix.Project.html
- ExDoc configuration: https://hexdocs.pm/ex_doc/Mix.Tasks.Docs.html
