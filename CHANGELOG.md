# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

Published Hex releases use `[0.x.y]` version headings in this file. Internal repository
milestone labels (such as `v2.x`) track delivery tranches — they are **not** a second
install axis and do not map to Hex versions.

## [Unreleased]

### Changed

- Bump `req_llm` peer dependency to `~> 1.13` (locked at 1.13.0)

## 0.1.1 (2026-05-30)

### Added

- Shared `Scoria.SupportJourney.Handlers` for overlay and gallery journey smokes
- Support copilot gallery optional lane journeys: semantic FAQ, knowledge, connector
- Gallery producer-path orchestrator smoke on `/scoria`
- `docs/MAINTAINERS.md` for CI topology and release operations
- `docs/connector_adoption.md` in Hex package and docs extras
- Named remote connector adoption lane (`mix test.connector`) with SupportJourney billing fixture proof

### Changed

- Support copilot gallery docs: clone-repo requirement and path vs tarball consumer distinction
- README: session keys for LiveView operator UI, deduplicated install steps, maintainer section at bottom
- Operator verification guide trimmed for adopters; maintainer content moved to `MAINTAINERS.md`

## 0.1.0 (2026-05-28)


### Features

* **02-01:** implement JSON-RPC 2.0 protocol handler ([abd2dd2](https://github.com/szTheory/scoria/commit/abd2dd2d28b9d6109084344dc83929373da2b379))
* **02-01:** implement MCP Plug Router ([61a3a5f](https://github.com/szTheory/scoria/commit/61a3a5fa13a67bbf111a7498b204226418d800ab))
* **02-02:** define Scoria.MCP.Tool behaviour ([ef00d95](https://github.com/szTheory/scoria/commit/ef00d95c1fd9671427d90d493d3f1d80f42345ae))
* **02-02:** implement Scoria.MCP.Validator ([172318d](https://github.com/szTheory/scoria/commit/172318d45764e0a59594a5f1adeb52c74f17e396))
* **02-03:** implement isolated executor with telemetry ([b768cb7](https://github.com/szTheory/scoria/commit/b768cb7069ebe13db48dc8a606420b9388ad20a2))
* **02-03:** wire the router pipeline with execution and validation ([ea99aab](https://github.com/szTheory/scoria/commit/ea99aabb524d5e30c3398da8f1d026cc104c27c5))
* **03-01:** add ScoriaWeb.Router macro and dependencies ([6397c56](https://github.com/szTheory/scoria/commit/6397c5642936f98b34ea2372592289582e4fe0e8))
* **03-02:** implement CSS Grid Trace Tree component ([27e3b18](https://github.com/szTheory/scoria/commit/27e3b18dcf3856b2259162e510b5252484cd45a9))
* **03-02:** wire PubSub and trace rendering in LiveView ([cbfe3ef](https://github.com/szTheory/scoria/commit/cbfe3ef36c98a2d95e7b333d860a77abec41cc3e))
* **03-03:** implement Approval schema ([16687c9](https://github.com/szTheory/scoria/commit/16687c99f748e4f0b09eee7a2b7a3cee2c71a453))
* **03-03:** implement HITL Approval Modals and Ecto Coordination ([7fd7e45](https://github.com/szTheory/scoria/commit/7fd7e45f051777e487484121bebf89866db7b1de))
* **03-03:** implement token stream coalescing ([219ca51](https://github.com/szTheory/scoria/commit/219ca5167681143822a4c58855c1a83320196a00))
* **03-liveview-operator-ux-01:** implement OrchestratorLive and configure tests ([0d7aae7](https://github.com/szTheory/scoria/commit/0d7aae70d4970ae4f2863208e4385106829c1874))
* **04-01:** implement evaluation flywheel schemas and context ([8143cc4](https://github.com/szTheory/scoria/commit/8143cc4ca9e89edbe7e80d39deeae234275abe67))
* **04-02:** implement ExUnit Evaluation Macro (EvalCase) ([5b6c1d8](https://github.com/szTheory/scoria/commit/5b6c1d87e30f181f6e304d73a640471b4d28cfa3))
* **04-02:** implement scoria.eval mix task ([fee33a3](https://github.com/szTheory/scoria/commit/fee33a327471ad1637b4e15962d089cd82b27848))
* **04-03:** implement dataset promotion and evalspec rubrics ([c213d0e](https://github.com/szTheory/scoria/commit/c213d0ee6cf30d40373593aeda43647dfad7cc4e))
* **04-03:** implement Promotion Context Logic ([06a6c69](https://github.com/szTheory/scoria/commit/06a6c6945fe401c2f70aabfd3745b1510cc2dd9b))
* **07-01:** add optional sre sink seams ([c4b8f23](https://github.com/szTheory/scoria/commit/c4b8f232a048d23a95a85afce53e42f6fd856fae))
* **07-01:** bootstrap sre public context ([080647d](https://github.com/szTheory/scoria/commit/080647de293cfe836fa71feccf1cd59be2844a48))
* **07-02:** enforce runtime and mcp budget preflight ([6ba1d5f](https://github.com/szTheory/scoria/commit/6ba1d5f840ed741e58bb17ae6c14b48ab6f8de60))
* **07-02:** implement budget engine reservations ([ae7fd63](https://github.com/szTheory/scoria/commit/ae7fd631fa3d7abdfa3522f1cf6a4f432e2201c2))
* **07-03:** add integration-scoped breaker guards ([7f9447e](https://github.com/szTheory/scoria/commit/7f9447eeedb89c6a1f46bee003efc07361654b9b))
* **07-03:** add sre telemetry helpers ([4c22b85](https://github.com/szTheory/scoria/commit/4c22b85c1da66aa887cedab04cb532b3b797fd2f))
* **07-04:** implement incident dedupe and severity routing ([ff6bc45](https://github.com/szTheory/scoria/commit/ff6bc458752d4297f7d839956be8f07e623cd789))
* **07-04:** implement transactional audit outbox capture ([b77bdc0](https://github.com/szTheory/scoria/commit/b77bdc05020e9cc7c875f71bbed41b0c5c2e6ed3))
* **07-05:** add trace-first incident evidence notebook ([7f43d68](https://github.com/szTheory/scoria/commit/7f43d6836770a47d3c158bba6c86b06e1115e05e))
* **07-05:** refresh trace badges from lazy SRE evidence ([5918e26](https://github.com/szTheory/scoria/commit/5918e2634139995b5526bc951354dbbe6d91feba))
* **07-06:** add durable sre budget and breaker persistence ([f82b39a](https://github.com/szTheory/scoria/commit/f82b39abca7c4dcccf0a8967a5bec4c4f2dc7b4f))
* **07-07:** add durable incident and audit storage nouns ([644e98d](https://github.com/szTheory/scoria/commit/644e98dfcf28996fc59b96f461ceb3e180bf48de))
* **07-08:** add optional first-party sink adapters ([6f75ffc](https://github.com/szTheory/scoria/commit/6f75ffc5b0ec1330b84ee50425eea57c547e527e))
* **07-08:** add supervised durable relay worker ([fa3eab0](https://github.com/szTheory/scoria/commit/fa3eab0f5ec3badc524817de9a5e7b12f406e655))
* **09-01:** lock approval audit attribution ([7583cd7](https://github.com/szTheory/scoria/commit/7583cd7b9ea66014b877c381d6a96ab2effc2f78))
* **09-01:** restore workflow-owned approval ui path ([9d1b758](https://github.com/szTheory/scoria/commit/9d1b758ad259c3622864dce65f60821c311beec4))
* **09-02:** produce durable incident delivery rows ([3e6ecf1](https://github.com/szTheory/scoria/commit/3e6ecf1730ee83a33566558bc6f24a1b9f05613c))
* **09-03:** expose durable incident delivery outcomes ([0a765c4](https://github.com/szTheory/scoria/commit/0a765c46d9c8446f95a12b6631cef87b54a293d2))
* **10-01:** emit canonical runtime telemetry from execution seams ([e82e934](https://github.com/szTheory/scoria/commit/e82e934734b8b9b68f918bfd3b8237f1294c9430))
* **10-01:** expose canonical telemetry identity contract ([6f2832c](https://github.com/szTheory/scoria/commit/6f2832ceb3fefa4198867a1185ade1076c9b2264))
* **10-02:** align parapet telemetry translation ([125f947](https://github.com/szTheory/scoria/commit/125f9477ebcd2cf5eeb6675bb2fb63c0906ab394))
* **10-02:** emit post-commit incident lifecycle telemetry ([cfdba13](https://github.com/szTheory/scoria/commit/cfdba13b4467d5ad604985ef68d70e8fbdc7641d))
* **19-01:** add durable connector job and vault posture ([7cfa755](https://github.com/szTheory/scoria/commit/7cfa7555a09d532734b6b38a11582bdc9ba6f770))
* **19-01:** add normalized connector boundary schemas ([c4d0fcd](https://github.com/szTheory/scoria/commit/c4d0fcdaa1f419dc7e3b5fb193796ff238fd7e12))
* **23-01:** implement tokenizer utility ([269ad3b](https://github.com/szTheory/scoria/commit/269ad3bc93e08c19d83a9024215591213a8b5ffb))
* **23-02:** implement prompt template schema and migration ([2a1161b](https://github.com/szTheory/scoria/commit/2a1161bfdb0b26b79537757df1002ef81fe3d54f))
* **23-03:** implement prompt registry context API with immutable updates ([35da112](https://github.com/szTheory/scoria/commit/35da112727c649970f7c4f7dc8d04e6b50f08160))
* **23-04:** add live route for prompt templates ([dc62634](https://github.com/szTheory/scoria/commit/dc62634941d7dfe2e27dea27fbd61592a9f55a0c))
* **23-04:** implement prompt template LiveView interface with token estimation ([9157155](https://github.com/szTheory/scoria/commit/9157155db046056c57789e2a469b2f606b54a5ee))
* **24-01:** generate ai_eval_datasets migration ([8d7dc7f](https://github.com/szTheory/scoria/commit/8d7dc7f9e358af5299a798d6aaa364553224579d))
* **24-01:** implement Dataset schema and validation ([e8b45ac](https://github.com/szTheory/scoria/commit/e8b45ac44c509ea9cd7b598e57699d1267b99f78))
* **24-01:** implement DatasetItem schema ([4bd6520](https://github.com/szTheory/scoria/commit/4bd65200f142b8a84e28a6388d37e0be27fcca24))
* **24-02:** implement dataset CRUD and state management in Eval context ([0c2f93f](https://github.com/szTheory/scoria/commit/0c2f93f29adc97eb0119cce3cfa96742b8a120fb))
* **24-03:** implement dataset promotion component ([98032d8](https://github.com/szTheory/scoria/commit/98032d88ee3b7c942aa0948b3ce833ac86f43e6e))
* **24-03:** inject promote button into trace explorer ([892ccd1](https://github.com/szTheory/scoria/commit/892ccd1c3f98bc48bbbf5ea6979dd3846445d7a9))
* **24-03:** integrate promote modal in workflow show liveview ([ac9cb7b](https://github.com/szTheory/scoria/commit/ac9cb7bfd6ad88c54f61d41c6f33a12f30c228c2))
* **25-01:** converge eval persistence onto canonical datasets ([06eb037](https://github.com/szTheory/scoria/commit/06eb037c6de10eda71990e8855b98bdd7fdc4690))
* **26-01:** implement release gate middleware for draft prompts ([66ed7e7](https://github.com/szTheory/scoria/commit/66ed7e7e7d27d9b363e4085b9b03eac2c3eb7724))
* **26-02:** implement prompt release workflow and approval handling ([0e548c6](https://github.com/szTheory/scoria/commit/0e548c6a3fcb7342b8a9fe44ec4836e0214e08bb))
* **26-03:** scaffold prompt release UI and fix DB testing concurrency ([b6261a7](https://github.com/szTheory/scoria/commit/b6261a7d0ab2130bc053131063b9c31fa3a32c1a))
* **27-01:** add scoria_mcp router macro for host integration ([ffdea33](https://github.com/szTheory/scoria/commit/ffdea333d430af1d19b653f5ec7350d8234c16f9))
* **27-01:** add session registry to application supervisor ([4f8d918](https://github.com/szTheory/scoria/commit/4f8d9188a1825dcf8e1fded717bcc64c671a10a3))
* **27-01:** implement MCP SSE controller and message ingestion ([da1134a](https://github.com/szTheory/scoria/commit/da1134afa87e5583da3fefb22720fed7717308ae))
* **29-01:** create Scoria.Runtime.Instance schema and migration ([5373da6](https://github.com/szTheory/scoria/commit/5373da632c6ddf9c58c70ab5864a1de1d8df28f0))
* **29-01:** implement context functions for runtime registration ([a0f73f6](https://github.com/szTheory/scoria/commit/a0f73f68bf77a014e0e78f397171309a97bbc104))
* **29-02:** setup Phoenix Presence for runtime observability ([8c2ba9a](https://github.com/szTheory/scoria/commit/8c2ba9ad9b07e021efa9083f1b3db8cccd9324a3))
* **29-02:** track MCP connections via Phoenix Presence ([77780e1](https://github.com/szTheory/scoria/commit/77780e1ff1c6d96f7ca5b7398e15529a571a9aaf))
* **29-03:** implement runtime posture rail and detail drawer ([a446406](https://github.com/szTheory/scoria/commit/a446406ebe10338d525dac1550180ba197227385))
* **29-04:** add memory notebook component for compaction audit ([f9b0bc1](https://github.com/szTheory/scoria/commit/f9b0bc1343cfefaa4a236668456c1a1431463d3d))
* **29-04:** integrate memory notebook into workflow show with reciprocal link ([d28e6c4](https://github.com/szTheory/scoria/commit/d28e6c437ceed44a4fc393327624127359ce9857))
* **30-01:** configure baseline and dynamic oban queues ([8bbcf94](https://github.com/szTheory/scoria/commit/8bbcf94b02704d59ba1717fd92a41435f0263405))
* **30-02:** implement BatchEnqueue chunking ([46972cf](https://github.com/szTheory/scoria/commit/46972cf1477464d13d83b02a3c4a6017db368149))
* **31-01:** implement Circuit Breaker Sweep Manager ([eba002b](https://github.com/szTheory/scoria/commit/eba002bdff1aeabcfc42f000149548405af68379))
* **31-01:** implement ETS Circuit Breaker State API ([fea7208](https://github.com/szTheory/scoria/commit/fea72085eb83916e3d6187efa3ac4d5fe4cb65cb))
* **31-02:** implement CircuitBreaker request step ([ebb42bd](https://github.com/szTheory/scoria/commit/ebb42bd2eb6c842d840f0fb3f55858aa374f44dc))
* **31-02:** implement Resiliency response and error steps ([e63b2f9](https://github.com/szTheory/scoria/commit/e63b2f93eccda9b161adc2a57f1fe9e304c85d92))
* **31-02:** implement Steps wrapper for Req pipelines ([33e796b](https://github.com/szTheory/scoria/commit/33e796b5c77b882bb17d15f1ef58290f4b707aac))
* **31-03:** inject req_options into application workers ([7131567](https://github.com/szTheory/scoria/commit/7131567c9ce9bcc97dac125b1f36bdb435a02340))
* **32-01:** Add default configuration for model fallback chains ([b97f7f2](https://github.com/szTheory/scoria/commit/b97f7f25d7ef2b53100302f3d3ba96b1b8512fd4))
* **32-01:** Implement Scoria.Orchestrator with recursive fallback and telemetry ([bf95885](https://github.com/szTheory/scoria/commit/bf95885df7214190fd5691ac804e16fd55f80811))
* **32:** integrate multi-model fallback orchestration and stabilize tests ([384536c](https://github.com/szTheory/scoria/commit/384536c446649dbdcb6728bca68401b0fe634d52))
* **33-01:** add eval campaign persistence foundation ([71f3e2e](https://github.com/szTheory/scoria/commit/71f3e2e856077ac0deeb69d8fe2db323de13d916))
* **33-02:** implement eval campaign fan-out coordinator ([a9eb4a9](https://github.com/szTheory/scoria/commit/a9eb4a913be8417a3ca297f427c58263a9feb17a))
* **33-03:** execute eval campaign targets through orchestrator ([9e68f36](https://github.com/szTheory/scoria/commit/9e68f36964d20c9886692c673558cf4054493140))
* **38-01:** add replay disposition resolver contract ([819c0e3](https://github.com/szTheory/scoria/commit/819c0e37279a703e995bcf899816fc88ed43c758))
* **38-01:** add replay run intent and approval authority fields ([e2e8e29](https://github.com/szTheory/scoria/commit/e2e8e29b3e3c37df2320c50cb498e6f7dd75a99d))
* **38-01:** persist replay evidence on checkpoints events and audit rows ([591ee5a](https://github.com/szTheory/scoria/commit/591ee5a012f642feb64b6d12cf7fc037b4974135))
* **38-02:** gate replay execution at connector and mcp seams ([2f8d805](https://github.com/szTheory/scoria/commit/2f8d805d338d6bb08f1a30d283e67d20eef9d537))
* **38-02:** rework replay-scoped approval transitions ([e242c05](https://github.com/szTheory/scoria/commit/e242c05c54c9b4b7027dd457c9159b67e7d5c080))
* **38-03:** expose replay-safe approval projection reads ([32f12f3](https://github.com/szTheory/scoria/commit/32f12f3b10ee6e13636da5943ff976302fcaa2e3))
* **38-03:** project replay posture through runtime dto reads ([a6e1aa4](https://github.com/szTheory/scoria/commit/a6e1aa44ecbf25959f41fb4c849f0b4b05253552))
* **39-01:** build replay comparison runtime DTOs ([406e3e5](https://github.com/szTheory/scoria/commit/406e3e5f130c99e3616c10ee3cf51971ae049a02))
* **39-02:** add replay evidence notebook ([92f57f3](https://github.com/szTheory/scoria/commit/92f57f34dd694c4f88fca0749d142bcb9a675cc1))
* **39-02:** add replay workflow page state ([20b289f](https://github.com/szTheory/scoria/commit/20b289fdf2368998d010e814707ca48ff3911286))
* **39-03:** freeze workflow-source dataset promotion ([3d67cb3](https://github.com/szTheory/scoria/commit/3d67cb3147bb010cbf883c861fc5369abd834165))
* **39-03:** route sealed dataset promotion through approvals ([5579017](https://github.com/szTheory/scoria/commit/5579017b3aeac94fdbc72289be35c4113d4389a4))
* **39-05:** fix replay promotion runtime contract ([f35884a](https://github.com/szTheory/scoria/commit/f35884a79b7187502425a111a9de5434b78f2ed5))
* **39-05:** persist replay promotion metadata end to end ([23cfc0f](https://github.com/szTheory/scoria/commit/23cfc0f2abf0525192289160ba96280594c88987))
* **40-01:** add online scoring storage substrate ([4be7a70](https://github.com/szTheory/scoria/commit/4be7a706ea299893f8784b9907002cfacb2a99ab))
* **41-01:** lock bounded handoff contract and lineage ([62049f5](https://github.com/szTheory/scoria/commit/62049f5fd9be4d518509f47252cc91ff6956798a))
* **48-01:** harden installer mutation reporting ([a754c66](https://github.com/szTheory/scoria/commit/a754c668e12567780c0495351a777d36f06e689d))
* **72:** Hex publish enablement and shift-left release automation ([197c929](https://github.com/szTheory/scoria/commit/197c92939a7fa250febd7f18f7c505c109a17370))
* **observability:** create Ecto schemas and migrations for traces, spans, and span events ([5cb78a4](https://github.com/szTheory/scoria/commit/5cb78a44ae2f156b81be4177a2e0617a751ba1dd))
* **observability:** implement async gen server buffer for spans ([e703a39](https://github.com/szTheory/scoria/commit/e703a39498ded15b6285cbbb8644a9c16a6254ee))
* **observability:** implement telemetry handlers and adapters ([58bb928](https://github.com/szTheory/scoria/commit/58bb928b287ad02ea6ee782d799b13234621ab70))
* **observability:** implement telemetry redaction engine ([800c2e1](https://github.com/szTheory/scoria/commit/800c2e115ecee660a969951df95b4226d089e0a4))
* **v1.9:** ship crucible operator loop ([252bbfc](https://github.com/szTheory/scoria/commit/252bbfc1d4062b25ff063bdcf28772a18c32b8b3))
* **v2.2:** finish OSS adopter onramp ([3d30442](https://github.com/szTheory/scoria/commit/3d3044240d8f74e49948c324118bfb00e1a4c722))


### Bug Fixes

* **26-03:** wire real approval logic and verification to prompt release ([ccb3e15](https://github.com/szTheory/scoria/commit/ccb3e15f7104aab86cbb0e7feb6270e98d3fe878))
* **31-01:** resolve compilation warnings and test suite concurrency flakiness ([39f0b68](https://github.com/szTheory/scoria/commit/39f0b68147e0adcfefd28addad5e688f0d68bd0d))
* **38:** preserve replay-live approval provenance ([245888e](https://github.com/szTheory/scoria/commit/245888e6de11b644f0c5ce236e8ab2d041615253))
* **39:** revise plans based on checker feedback .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-03-PLAN.md .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-04-PLAN.md .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-05-PLAN.md .planning/phases/39-replay-operator-ux-draft-dataset-promotion/39-VALIDATION.md .planning/ROADMAP.md ([51bdba2](https://github.com/szTheory/scoria/commit/51bdba29706dbecef7cd7b03998ad8d930924b85))
* **41-02:** harden projected context validation ([1d3d4e8](https://github.com/szTheory/scoria/commit/1d3d4e81a83c34279a405e4059b9331be4a208ac))
* **45:** revise plans based on checker feedback .planning/phases/45-compatibility-and-invalidation-engine/45-00-PLAN.md .planning/phases/45-compatibility-and-invalidation-engine/45-01-PLAN.md .planning/phases/45-compatibility-and-invalidation-engine/45-02-PLAN.md .planning/phases/45-compatibility-and-invalidation-engine/45-03-PLAN.md .planning/phases/45-compatibility-and-invalidation-engine/45-RESEARCH.md .planning/phases/45-compatibility-and-invalidation-engine/45-VALIDATION.md .planning/ROADMAP.md ([290d9d0](https://github.com/szTheory/scoria/commit/290d9d07751a7cd78c86ff11f4a2b2bcd8602d50))
* **50-01:** lock release preview command contract ([be552b0](https://github.com/szTheory/scoria/commit/be552b0f47dd1d82d819597f00c79410dda8cf82))
* **50-01:** run release preview lane in dev env ([5c24c78](https://github.com/szTheory/scoria/commit/5c24c78054890f2cd31a80b2ce9730f2593dfaa4))
* **72:** allow Release PR manifest 0.1.0 in ci policy contract ([e1e697c](https://github.com/szTheory/scoria/commit/e1e697c20d91c51a5571d2fbd3f54ca43591dbf9))
* bootstrap pgvector in knowledge lane ([f94c98a](https://github.com/szTheory/scoria/commit/f94c98a310bd0c8f24961cb7aa98ecff0a0fb5b2))
* **eval:** fix update_eval_spec merging keys ([4d547eb](https://github.com/szTheory/scoria/commit/4d547eb36125777adbe7d1043a3473f2ab611685))
* **phase-10:** stabilize bootstrap verification lanes ([a0a31e7](https://github.com/szTheory/scoria/commit/a0a31e71de0a58c6a5fd431c9be64fc989899e95))
* **phase-39:** close post-review replay promotion gaps ([118b9f5](https://github.com/szTheory/scoria/commit/118b9f57cf09775ed81157bc3815c4ff18c84271))
* **ui:** add assign_async for trace metadata lazy loading ([52f0d6f](https://github.com/szTheory/scoria/commit/52f0d6ff562b6c558cf05d4728cc48baa5b8ef5b))

## [Unreleased]

## [0.1.0]

First public Hex packaging of Scoria's in-repo capability through the v2.6 warning-ratchet
closeout. Integrators get a Phoenix-native runtime with durable runs, bounded escalation,
optional semantic reuse, and executable adoption lanes — without adopting internal planning
milestone names as product releases.

### Added

- **Default runtime** — identity-aware durable runs, approvals, and operator evidence via
  `Scoria.start_run/2`, `Scoria.resume_run/2`, and `/scoria` inspection surfaces; prove with
  `mix scoria.test.adoption`.
- **Bounded handoff** — narrow same-run delegation with projected context and visible lineage
  through `Scoria.start_handoff_run/3`; prove with `mix scoria.test.runtime_to_handoff`.
- **Semantic fast path** — tenant-scoped reuse for explicitly safe read-only lanes via
  `Scoria.SemanticLane`; prove with `mix scoria.test.semantic_fast_path`.
- **Optional knowledge** — pgvector-backed retrieval when chosen; prove with
  `mix scoria.test.knowledge`.
- **Upgrade-safe install** — planner/check/apply paths via `mix scoria.install --dry-run`,
  `mix scoria.install --check`, and `mix scoria.install`.
- **Maintainer CI trust** — warning baseline and ratchet enforcement, policy→test topology
  guarded by contract tests, and local parity via `mix scoria.test.ci_trust` (maintainer-only;
  not an adopter integration requirement).

### Roadmap traceability

| Planning tranche | Shipped | Reference |
|------------------|---------|-----------|
| v2.1 | 2026-05-25 | [`.planning/MILESTONES.md#v21-tenant-scoped-semantic-fast-path`](.planning/MILESTONES.md) |
| v2.3 | 2026-05-27 | [`.planning/MILESTONES.md#v23-runtime-to-handoff-adoption-example`](.planning/MILESTONES.md) |
| v2.4 | 2026-05-27 | [`.planning/MILESTONES.md#v24-adoption-reliability-contract`](.planning/MILESTONES.md) |
| v2.5 | 2026-05-27 | [`.planning/MILESTONES.md#v25-installer-safety--upgrade-confidence`](.planning/MILESTONES.md) |
| v2.6 | 2026-05-28 | [`.planning/MILESTONES.md#v26-warning-ratchet`](.planning/MILESTONES.md) |
