# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Planning milestones vs Hex releases

Published Hex releases use `[0.x.y]` version headings in this file. Internal repository
milestone labels (such as `v2.x`) track delivery tranches — they are **not** a second
install axis and do not map to Hex versions.

## [0.1.3](https://github.com/szTheory/scoria/compare/v0.1.2...v0.1.3) (2026-07-11)


### Features

* **37-04:** build the Overlays curated flow-probe section ([53d186f](https://github.com/szTheory/scoria/commit/53d186fb292a0a108305a8dead7520a7262daf2c))
* **37-05:** build DevLab.LabLive shell and section dispatch ([900768e](https://github.com/szTheory/scoria/commit/900768e277a35997e732f629e98334d166ce1194))
* **37-05:** mount dev-only lab route in dev/dev_router.ex ([476ba08](https://github.com/szTheory/scoria/commit/476ba08cbb4437d27e9ef141a09e0405c577c5a0))
* **37-06:** add deterministic lab browser proof (lab.spec.mjs) ([247ca20](https://github.com/szTheory/scoria/commit/247ca2015949224572af07eb134e43aa9d2dd492))
* **38-01:** add opaque toast tokens and repoint toast/flash CSS (GREEN) ([3c0f1af](https://github.com/szTheory/scoria/commit/3c0f1af439981dc09357afe93f924af1c27c0425))
* **38-02:** close copy-control a11y gaps (aria-live, aria-label) ([96b593e](https://github.com/szTheory/scoria/commit/96b593efc07d6192190d8e0a1bce88ae5d92d74a))
* **38-02:** delete signal_strip duplicate and guard stat singularity ([dc49af6](https://github.com/szTheory/scoria/commit/dc49af6f650c001f4631bd0f4690a047b5057b72))
* **39-01:** add page_header/1 to ScoriaWeb.UI ([8d9ac90](https://github.com/szTheory/scoria/commit/8d9ac90c1c4c3af2365b9f0b6e8b977e0e64331f))
* **39-01:** additively upgrade status_label/1 with curated D-25 vocabulary ([45d1b94](https://github.com/szTheory/scoria/commit/45d1b944d245799a3f296db0191a4a2a6fb4bee9))
* **39-02:** add per-domain copy modules (Incident/Dataset/Review/Connector) ([517d275](https://github.com/szTheory/scoria/commit/517d2750317d8400876defd67134e124f12e0d24))
* **39-02:** add strings-only ScoriaWeb.Copy ([bf19553](https://github.com/szTheory/scoria/commit/bf19553d8dd4fe6d23419685b1d4ca30e9f785ea))
* **39-03:** add Workflows.list_decided_approvals/1 (bounded projection, D-20) ([f64c01e](https://github.com/szTheory/scoria/commit/f64c01e7f3b7a8f793b8321816425cbd81d7fc42))
* **39-03:** extend ApprovalCopy as the decision-copy SSOT (D-16, D-24d, D-27) ([89fb198](https://github.com/szTheory/scoria/commit/89fb19818ea82af0a57b51a58267afb73e3d09b0))
* **39-03:** route decided/expired fixtures through approve/3, guard the write invariant ([86d35dd](https://github.com/szTheory/scoria/commit/86d35dde1ed957b94006b75feab665d6fb730c7b))
* **39-04:** migrate eval-spec/prompt headers, fix D-23 microcopy offenders ([f7b9312](https://github.com/szTheory/scoria/commit/f7b931214463dbcd429a053c6992af083987b1ca))
* **39-04:** migrate orchestrator Home + workflow index to page_header/1 ([e2286a6](https://github.com/szTheory/scoria/commit/e2286a6589bbe4497fd2a0b10a99afe8e588da9c))
* **39-04:** reconcile coming_soon_live's two hand-rolled header shapes ([8448b68](https://github.com/szTheory/scoria/commit/8448b68acd7a413dfd48b9097d1c9aee469977a1))
* **39-05:** incidents page_header + stream the selectable list (D-10) ([6c01997](https://github.com/szTheory/scoria/commit/6c019977870dc7264e90f612f938ae818f5b7746))
* **39-05:** normalize dataset/connectors page_header, D-04/D-23 microcopy, D-08 states ([e2479c3](https://github.com/szTheory/scoria/commit/e2479c3b0f7c34eef1a688d4d25034ee49d44449))
* **39-05:** review_queue page_header, URL-held filter, D-23/D-08 fixes ([eba95a0](https://github.com/szTheory/scoria/commit/eba95a0b160a49ecc3c4a240a2cfb93d55c87ef8))
* **39-06:** confirm modal earns friction, Deny neutral, decided gate, alarm CSS removed ([2efcbe2](https://github.com/szTheory/scoria/commit/2efcbe297dfd2a6c726c5b718135e12d994afa71))
* **39-06:** re-sequence approval drawer decision-first, de-alarm, dedup copy ([ce86c88](https://github.com/szTheory/scoria/commit/ce86c88d948f831a5451fc42686af0eda81458d3))
* **39-06:** split approval payload into two native disclosures + stable DOM id ([22f9e16](https://github.com/szTheory/scoria/commit/22f9e169c3c4f107bc011b8160ee767361758637))
* **39-07:** decided read-only receipt drawer + audit-sourced attribution ([99ed2a4](https://github.com/szTheory/scoria/commit/99ed2a4762ae272f359f4d3bc552d25c67154bb5))
* **39-07:** Pending|Decided URL scope + ?approval deep-link on approvals table ([522b0cb](https://github.com/szTheory/scoria/commit/522b0cba91af504cf863275d27c288775d5ab2a7))
* **40-01:** add shared axe-run and boxesIntersect helpers ([9d8d0db](https://github.com/szTheory/scoria/commit/9d8d0dbf05a3966767723288c6c3a1275f397741))
* **40-01:** pin @axe-core/playwright 4.12.1 dev-only with axe-core override ([715cb72](https://github.com/szTheory/scoria/commit/715cb721ac8281a539b535607d5ec91c9ff64d37))
* **40-02:** add A11Y structural-presence source-scan guard ([5188d25](https://github.com/szTheory/scoria/commit/5188d257c3ef3a8acf72110d1ab35861afda9580))
* **40-02:** add MOTION-01 tokenization + keyframe source-scan guard ([15ec2e4](https://github.com/szTheory/scoria/commit/15ec2e4fa0f3454f09c0f89cdccf63c4023a8396))
* **40-03:** add focus trap + restore to drawer/1 and modal/1 ([cbe1288](https://github.com/szTheory/scoria/commit/cbe12883abeb96bcdde5d10af172a01c4e93cad0))
* **40-04:** add report-only axe WCAG 2.2 AA baseline for full dev lab ([dcdd5ba](https://github.com/szTheory/scoria/commit/dcdd5ba02f4d1ec1d6cca5ce1f3338c2013f4382))
* **40-04:** curated axe assert-zero scan on all 7 seeded real pages ([088e85d](https://github.com/szTheory/scoria/commit/088e85d4ae5be7cd1857d7776410df05dc4066e3))
* **40-05:** reduced_motion.spec.mjs proves duration collapse incl. infinite skeleton ([0116e39](https://github.com/szTheory/scoria/commit/0116e39dc52ec28336a7e1cae5733de07320ed4e))
* **40-05:** responsive_scan.spec.mjs — D-16 tiered assertion catalog across 4 anchor pages ([72bc857](https://github.com/szTheory/scoria/commit/72bc85747208c6b9602ecce2340faa114e1e5779))
* **40-05:** widen shots.mjs to the 6-width matrix for contact-sheet evidence ([3cfb079](https://github.com/szTheory/scoria/commit/3cfb0799ac42ce3857fd151046648ba03d98258a))
* **41-04:** add /_lab/overlays to screenshot SCREENS with toast-timing-safe capture ([2d914ec](https://github.com/szTheory/scoria/commit/2d914ecc0b57d1394b1225b7401f13a270e26919))
* **41.1-01:** delegate UI.status_label/1 to Copy.status_label/1 + parity guard ([c61e0be](https://github.com/szTheory/scoria/commit/c61e0be7656403ca768feb49e88be6ef47e03b37))
* **41.1-01:** wire dataset_live/index.ex to Copy + DatasetCopy, byte-stable ([0ae707f](https://github.com/szTheory/scoria/commit/0ae707fba71a838fbf3f0c783c11985431b34bf3))
* **42-01:** allow not_scored scores without measurements ([d328ad5](https://github.com/szTheory/scoria/commit/d328ad58d7fa3520f5c6dcf0f1895156fb91a36b))
* **42-01:** implement fail-closed verdict spine ([07572d1](https://github.com/szTheory/scoria/commit/07572d1a3f43f6b1a495ee37a2dfa598a167049b))
* **42-01:** render eval inconclusive states as warnings ([33eb786](https://github.com/szTheory/scoria/commit/33eb7861bc140003d85c1749347696437c246f8f))
* **42-02:** add dataset item capture fields ([d792cae](https://github.com/szTheory/scoria/commit/d792caedbc77f6a1954ec3d6846c44baba9a4cb2))
* **42-02:** capture workflow step output on promotion ([2b19e2f](https://github.com/szTheory/scoria/commit/2b19e2fe931af0b6aaa3842a6f0f16bf30bd81e2))
* **42-02:** implement subject output resolver ([861a917](https://github.com/szTheory/scoria/commit/861a9171c72bc73c99fd569986bab6bcb7f2a957))
* **42-03:** add minimal exact match scorer ([bb3a330](https://github.com/szTheory/scoria/commit/bb3a330a1cb1c8ba0f4916751985bf1f138877d3))
* **42-03:** implement exact match scorer behavior ([f0c41c3](https://github.com/szTheory/scoria/commit/f0c41c3d504dac39382ad5bbb35e1faa9deb81ef))
* **42-04:** score offline replay with real scorer dispatch ([ed54fc4](https://github.com/szTheory/scoria/commit/ed54fc45f9ee73a4e6b37b6b0e893ee90bcf8eee))
* **42-05:** route judge runner through captured output ([2cc621b](https://github.com/szTheory/scoria/commit/2cc621ba717c9981c42b224748f8d41516555e34))
* **42-06:** classify online negative signals ([85e6839](https://github.com/szTheory/scoria/commit/85e68391a916964db215699e67089e522ade66dc))
* **42-06:** gate online summaries with verdict ([639b007](https://github.com/szTheory/scoria/commit/639b007274bdfd6f267d303cc1772ac070ddabae))
* **42-07:** add eval run verdict lookup index ([5dc694a](https://github.com/szTheory/scoria/commit/5dc694a10070552ca8561728fb55abfbb00f40ef))
* **42-07:** add release gate verdict consult ([ebdadd6](https://github.com/szTheory/scoria/commit/ebdadd684ca28f15075a169e2d6b084c635b8222))
* **43-01:** add knowledge scope contract ([068224c](https://github.com/szTheory/scoria/commit/068224cad9613dc7123bcffe43e0261c65ae0552))
* **43-02:** add knowledge tenant scope migration ([cee298a](https://github.com/szTheory/scoria/commit/cee298a327edefd85e0b20c57365f949f87a9b04))
* **43-02:** add knowledge tenant scope schema fields ([671315a](https://github.com/szTheory/scoria/commit/671315aa67663a7aa8e9a7746185494a73b6687a))
* **43-03:** enforce retrieval scope persistence ([a43d4d4](https://github.com/szTheory/scoria/commit/a43d4d4fde75ca6dee92298e1a76dc79c7702def))
* **43-03:** enforce scope on knowledge source paths ([26904c4](https://github.com/szTheory/scoria/commit/26904c4622ed73a07280249203aa35a676455c09))
* **43-04:** pass scope into knowledge backends ([d1448ff](https://github.com/szTheory/scoria/commit/d1448ff655a3519e61368727c57917c49fbe39ca))
* **43-04:** tenant filter pgvector retrieval ([1d008a7](https://github.com/szTheory/scoria/commit/1d008a7e4625355a225cf5cd5ba993d1ae381ac0))
* **43-04:** tenant qualify scrypath normalization ([55d16f8](https://github.com/szTheory/scoria/commit/55d16f8d4eebfe34eee1e0a53cb47ddea5364d39))
* **43-05:** route grounding through scoped citations ([dcc14b9](https://github.com/szTheory/scoria/commit/dcc14b93cace03c4fbb512b2029e52c704cf822f))
* **43-05:** scope citation validation and audit ([d9be295](https://github.com/szTheory/scoria/commit/d9be295363b7a36349c0b84ff876e0a25eb4c0b7))
* **44-01:** add fail-closed dashboard scope gate ([8e38b55](https://github.com/szTheory/scoria/commit/8e38b5571aa3fce3ff4c904321ffd3610f1e3902))
* **44-01:** wire dashboard auth hook chain ([1c15790](https://github.com/szTheory/scoria/commit/1c15790b4ac5e46618bfcc27f01c6eb609d32295))
* **44-02:** consume dashboard scope in auth seam views ([fe16315](https://github.com/szTheory/scoria/commit/fe1631574668814054fba22d1d35eb46963b0a0e))
* **44-03:** route approvals through dashboard scope ([2803061](https://github.com/szTheory/scoria/commit/28030615e71f72662dcb6c36e6fad48418f2237e))
* **44-04:** tenant-scope workflow dashboard reads ([94e9c40](https://github.com/szTheory/scoria/commit/94e9c402f8beab71be60dae1ff61128ba724784a))
* **44-05:** add tenant-aware eval dashboard helpers ([152f5f1](https://github.com/szTheory/scoria/commit/152f5f1e68dcf3617be53d8cdc09efceef52f088))
* **44-05:** wire quality dashboards to tenant scope ([fb9f95a](https://github.com/szTheory/scoria/commit/fb9f95a818392e03de45db22fed961222fbe008a))
* **44-06:** scope prompt release evidence ([a235e3c](https://github.com/szTheory/scoria/commit/a235e3cf8d4a91825a1fe4fed333ad3f19817e8e))
* **46-01:** add reviewer broadcast compatibility surface ([3e7fec9](https://github.com/szTheory/scoria/commit/3e7fec9e8ccea7b95a774c4fcf95134160b5ace1))
* **46-01:** add verification suites compatibility surface ([69789d4](https://github.com/szTheory/scoria/commit/69789d4123810ebad6bf0d64fb1fae841b620a1e))
* **46-02:** add reviewer surface compatibility alias ([5c7d839](https://github.com/szTheory/scoria/commit/5c7d8393b6605ab20255a739bf07e964b68cbed2))
* **46-03:** add semantic cache profile aliases ([adc3247](https://github.com/szTheory/scoria/commit/adc32475dd396ccff7b2c22a55fea6f91e0cbabf))
* **46-04:** migrate workflow adapters to trace components ([7dba6b3](https://github.com/szTheory/scoria/commit/7dba6b32aca8f90f47524b01f4b05682c9308f5a))
* **46-05:** normalize trace evidence copy boundary ([5919088](https://github.com/szTheory/scoria/commit/59190886d74662cdf929a5fd1c12390fbc7ac03c))
* **46-06:** expose glossary in docs package surface ([f32b52f](https://github.com/szTheory/scoria/commit/f32b52f70989c00d92314659ec1a92ee8d047168))
* **48-07:** add docs source metadata helpers ([0c8d3b5](https://github.com/szTheory/scoria/commit/0c8d3b597a18ee862322e70d244e6b752b8b88a3))
* **48-07:** align release preview docs inventory ([e4f7911](https://github.com/szTheory/scoria/commit/e4f7911b8b1c48e799644f5bfd6c671640191135))
* **48-07:** configure ExDoc guide surface ([2255e61](https://github.com/szTheory/scoria/commit/2255e615d556b0aedc0e87c6dede47c868376110))
* **49-01:** add AI docs contract constants ([2e45f5a](https://github.com/szTheory/scoria/commit/2e45f5a90e730d5b6ec1b7b47ca3b9fd0fdc4e3c))
* **49-01:** add root AI docs entry points ([d90413e](https://github.com/szTheory/scoria/commit/d90413efdf32e0bb4ab66fdf86e40684f408913f))
* **49-02:** enforce docs warnings in release preview ([a1306cb](https://github.com/szTheory/scoria/commit/a1306cb29ceba191b27d109e70bb15bdecc709dc))
* **49-02:** make docs warnings gate clean ([9fe0953](https://github.com/szTheory/scoria/commit/9fe0953606a6ed37085ffbe494c7c7e87880b254))
* **49-02:** package shared root AI docs ([1935020](https://github.com/szTheory/scoria/commit/1935020a440db93c96ff9d77c7445a3081fb2e48))


### Bug Fixes

* **38-01:** regenerate compiled dashboard CSS from token/component sources ([f519394](https://github.com/szTheory/scoria/commit/f519394ee842c1c60d099ecd63407da48f1910c2))
* **40-04:** repoint --scoria-text-subtle off pumice-500 to clear AA contrast ([43bdadf](https://github.com/szTheory/scoria/commit/43bdadfdf8df3a005b0f1acc8a318946b04c3595))
* **40:** CR-01 gate drawer window-Escape while a modal is stacked on top ([096154d](https://github.com/szTheory/scoria/commit/096154d3e157014b6c7daad054d9fb8b9419fd55))
* **40:** WR-03 clear the other connectors drawer when opening one ([52921c0](https://github.com/szTheory/scoria/commit/52921c029636ec700560ba3705a9c4e6b1ca1d84))
* **41-01:** add aria-label to .scoria-table__viewport, tighten a11y guard ([38a891e](https://github.com/szTheory/scoria/commit/38a891ed8c30cb5ce3ba5cf15bc1eee8ac251259))
* **41-01:** add exhaustive else to dismiss_candidate with clause ([d90dc97](https://github.com/szTheory/scoria/commit/d90dc9729f8304c1b2e537501e540997d9940789))
* **41-01:** assign safe :origin_context default in mount/2 ([f35b136](https://github.com/szTheory/scoria/commit/f35b136265e01fc8b1633cb7bb59e47a13acdba2))
* **41:** namespace guard-test ErrorView to avoid parallel-compile collision ([f6e3e0c](https://github.com/szTheory/scoria/commit/f6e3e0c60945fb3364a2c1a075b59be1b3081896))
* **43:** resolve research questions from checker feedback ([11e949f](https://github.com/szTheory/scoria/commit/11e949f288e36c7ebec3e468f7c5a14c76418655))
* **44:** close dashboard auth review blockers ([bc293bb](https://github.com/szTheory/scoria/commit/bc293bbab916bfece2c6b2da8359162bb7c03a45))
* **44:** revise dashboard auth seam plans ([3d82c58](https://github.com/szTheory/scoria/commit/3d82c58774ea7edfa1c0f11514cb05380903d073))
* **45-01:** project pgvector cosine retrieval scores ([b36953d](https://github.com/szTheory/scoria/commit/b36953d514058334a339f52186a3d635e5411221))
* **45-02:** repair grounding labels and chunk offsets ([03d9bef](https://github.com/szTheory/scoria/commit/03d9bef8de16373a4b13f27514d4cdcced25ecda))
* **45-03:** measure offline and judge eval latency ([1de6ea0](https://github.com/szTheory/scoria/commit/1de6ea0d1e7c54c9e20b620dd005148326591e71))
* **45-04:** measure online scoring latency ([57ad733](https://github.com/szTheory/scoria/commit/57ad7336a52c239c053f23bd1d4a482f613d986d))
* **46:** revise terminology plans from checker feedback ([861ff2f](https://github.com/szTheory/scoria/commit/861ff2f12c01716972bedbf3364a0be5735de5a2))
* **47:** address code review findings ([6d87120](https://github.com/szTheory/scoria/commit/6d87120ec27c6850c913372ccff67ef37f295b30))
* **47:** align package surface changelog guard ([defeb56](https://github.com/szTheory/scoria/commit/defeb560542e0167ddcbb5fd0e985c44a907d9a6))
* **47:** require changelog in release preview ([e017fca](https://github.com/szTheory/scoria/commit/e017fcaaba8af03f9c225b1bf5169b1685f3bbdd))
* **47:** revise planning artifacts based on checker feedback ([c26b243](https://github.com/szTheory/scoria/commit/c26b243a029a0e6a856f08ee5989a9c8e090c8c2))
* **48:** clean generated docs before release preview ([04de4db](https://github.com/szTheory/scoria/commit/04de4db4e22ff2832ec283338b29384c33e62681))
* **48:** close guide contract drift after wave 3 ([6e765a6](https://github.com/szTheory/scoria/commit/6e765a64731e4ff832a08f27e16c3e41edd5f416))
* **48:** preserve scope doctrine in compatibility stubs ([5c5ba9f](https://github.com/szTheory/scoria/commit/5c5ba9ff3c63d91f9d2a690f35f791105bbbaa31))
* **48:** resolve planning revision findings ([1d89acf](https://github.com/szTheory/scoria/commit/1d89acfd7388355b81b18ba35155e92c90f4964f))
* **48:** revise phase plans for checker feedback ([9cf8cd4](https://github.com/szTheory/scoria/commit/9cf8cd4ac21adbeeac4966cc3a1a62d30cafed9e))
* **48:** revise plans based on checker feedback ([f5f4bae](https://github.com/szTheory/scoria/commit/f5f4baef71669e043e1342fc0dade673b4636c12))
* **49:** resolve research open questions ([d4693dc](https://github.com/szTheory/scoria/commit/d4693dccbbc9a4f7c6102a21c172953bf0c49166))
* **49:** revise plans based on checker feedback ([d77b3a1](https://github.com/szTheory/scoria/commit/d77b3a16b353f9aaf7a94a7b618e99635e838a37))
* **50-01:** unbreak docs release-preview gate (D-50-DEF-01) ([c809241](https://github.com/szTheory/scoria/commit/c809241c39125577dd10ce6f183ad8304e28b3b1))
* **50-02:** pass tenant_id to start_release_workflow/3 in dev seed ([7a24315](https://github.com/szTheory/scoria/commit/7a243155768733a60cab2b1ed4c86f0109dcc368))
* **50-02:** scope theme-toggle locators to the visible desktop control ([75ee88a](https://github.com/szTheory/scoria/commit/75ee88a189e55e1c9399c40bfc1aea2ba87fadc2))
* **50-05:** repair DashboardScope bare-halt regression under LiveView 1.1.30 ([69e660a](https://github.com/szTheory/scoria/commit/69e660a9a5998f45e3a1a25266c1f9946136d29f))
* **50-06:** repoint handoff/semantic docs-source tests to guides/ SSOT ([e9fe82f](https://github.com/szTheory/scoria/commit/e9fe82f5d408f28e6eeb5d9ab07d8ecd12a43f19))
* **50-06:** repoint phoenix_example_source_test to per-guide fragment groups ([b8867e6](https://github.com/szTheory/scoria/commit/b8867e6708988cc3b95c3feae6f956e732fae5ae))
* **50-06:** repoint SupportJourney adopter doc surfaces to canonical guides/ ([ee7f53f](https://github.com/szTheory/scoria/commit/ee7f53f5521d31472910b174c20233f2cc28db6a))
* **50-07:** align seeded-run tenant scope with operator LiveView mount ([0d540fc](https://github.com/szTheory/scoria/commit/0d540fc7a38068087b27bf7abe2b15ca85ccdaef))
* **50-07:** repoint notebook-primitive and incident-evidence tests to relocated/reworded SSOT ([2618fce](https://github.com/szTheory/scoria/commit/2618fcef94c19314a9fcebca1d5c0d270f6c72cb))
* **50-08:** repoint dev_lab_boundary guard [#7](https://github.com/szTheory/scoria/issues/7) to archived 36-inventory.json path ([8e019e7](https://github.com/szTheory/scoria/commit/8e019e702fc4d8f10ec11f255f3dde4d824980d8))
* **50-08:** repoint ui_component_test maintainer-doc reads to guides/maintainers.md ([72fa708](https://github.com/szTheory/scoria/commit/72fa708f6eef08d3f97e4ebcec1fa1a78ec34de1))
* **50-09:** repair tenant-scoped knowledge seed and repoint approvals vocab drift in gallery app ([44eda48](https://github.com/szTheory/scoria/commit/44eda48cb395f009aad018c80f69e7ce773a0538))
* **50-10:** align package_surface_test homepage_url to REL-03 subdomain SSOT ([5258266](https://github.com/szTheory/scoria/commit/5258266d297b4096b6dfbf1ba6dc59c0207b2328))
* **50-11:** unbreak ExDoc release-preview gate on docs/design_system.md dev-only cross-link ([37494e5](https://github.com/szTheory/scoria/commit/37494e54b4d0d46354306e9c8a9fe81c001328af))

## [Unreleased]

### ⚠ BREAKING CHANGES (`0.1.4` cut)

**ReqLLM observability adapter attribute key rename.** Scoria.Observe.Adapters.ReqLLM
now emits OTel-GenAI / OpenInference convention keys (`gen_ai.*`, `server.*`,
`openinference.span.kind`) instead of Scoria's own ad hoc keys. This is a **clean
replacement — no dual-emit, no runtime shim, no config flag.** No adopter Postgres
database has ever actually persisted the old keys: a separate pre-existing bug (the
`ai_spans.trace_id` foreign-key gap, fixed alongside this change) meant every span
emitted through Scoria.Observe.Buffer was silently dropped before reaching the
database, so there is zero legacy row data to protect.

| Old key | New key(s) | Note |
|---|---|---|
| `llm.model_name` | `gen_ai.request.model` (requested) / `gen_ai.response.model` (actually used) | Was a single string; now split into request-vs-response semantics — some providers silently route to a different underlying model than requested |
| `llm.token_count` | `gen_ai.usage.input_tokens` + `gen_ai.usage.output_tokens` | Was a single total; reconstruct the old total as `input_tokens + output_tokens` if you need it |
| `req.url` | `server.address` + `server.port` | **Lossy**: the old key held a presumed full request URL; the new keys hold only host + port, not path. Combine with `gen_ai.operation.name` (e.g. `"chat"`) for "what kind of call, to what host" — not literal path-level detail |

If you attached a custom `:telemetry` handler to `[:scoria, :observe, :span, :stop]`
that reads the old key names out of `attributes` in memory, update it to read the new
`gen_ai.*`/`server.*` keys above.

**New persistence-failure observability.** Scoria.Observe.Buffer no longer silently
swallows flush failures with a bare `rescue`. A new `[:scoria, :observe, :buffer,
:flush_error]` telemetry event fires on every failed flush (logged by default), and a
new `:on_flush_error` `Buffer` start-link option (`:log` default | `:raise`) lets you
choose whether a persistent Postgres failure should crash the buffer process instead
of only logging.

### Migration Required (per-run rails, RAIL-01)

The pre-1.0 terminology migration described below requires no schema change, and the
per-run rails feature described here adds one.

**One new migration: `20260728120000_add_rail_columns_to_ai_workflow_runs.exs`.** This
migration adds seven columns to `ai_workflow_runs`: `rail_max_steps`,
`rail_max_tool_calls`, `rail_max_active_ms`, `rail_steps`, `rail_tool_calls`,
`rail_paused_ms`, and `rail_paused_at`. It is catalog-only — there is no backfill, so
every existing row reads zero counters and null limits, and every pre-existing run
behaves exactly as before. **Hosts must run their migrations after upgrading** (`mix
ecto.migrate`); see [Troubleshooting](guides/troubleshooting.md) for the failure symptom
if this step is skipped.

**A new terminal run status: `"halted"`.** A run that exceeds a configured rail now
reaches this status instead of being silently allowed to continue.

**A new audit-outbox event type: `"run.rail.tripped"`.** Call this out explicitly if you
maintain a custom `Scoria.SRE.AuditSink` implementation: `SRE.Relay` is
event-type-agnostic and every in-repo UI filter is positive, but an adopter's own sink
that pattern-matches `event_type` exhaustively could crash on an unrecognised value
unless it is updated to handle `"run.rail.tripped"` before upgrading.

See [Per-Run Rails](guides/capabilities/per-run-rails.md) for the full capability guide.

### Added

**Scoria.Observe.Buffer now boots automatically.** Spans emitted by Phases 51/52
(Scoria.Observe.emit_*_span/1 and any custom `:telemetry.execute/3` on
`[:scoria, :observe, :span, :stop]`) were previously inert outside of tests:
Scoria.Observe.Buffer was never a supervised child of Scoria.Application and
Scoria.Observe.Telemetry.attach/1 had no `lib/` caller, so every span fired into a
void in a real host app. Scoria.Application.start/2 now starts
Scoria.Observe.Buffer under `Scoria.Supervisor` and calls
Scoria.Observe.Telemetry.attach/0 on boot, so spans persist to Postgres with zero
host wiring. Opt out with `config :scoria, Scoria.Observe, enabled: false`.

**The ReqLLM and Jido adapters now boot-attach too.** Scoria.Application.start/2
also calls the new `safe_attach_observe_req_llm/0` and `safe_attach_observe_jido/0`
helpers this release adds, so their LLM/TOOL spans **persist to Postgres with zero host wiring**,
the same as the default pipeline above. One caveat: a persisted adapter span only
joins the current workflow run's trace as a child of the step span when the host
forwards `trace_id`, `parent_id`, and `tenant_id` into the call's telemetry
metadata. That forwarding is automatic for calls made inside
Scoria.Workflows.Runtime.execute_step/2; a raw call made outside a workflow
persists as a standalone single-span trace until the host forwards those keys
itself. See
[LLM and Tool Adapters](guides/capabilities/llm-and-tool-adapters.md) for the full
metadata-forwarding contract. Note that `jido` is not a Scoria dependency: the Jido
handler stays dormant unless the host app itself depends on and runs Jido. Opt out
of both adapters the same way, with `config :scoria, Scoria.Observe, enabled: false`.

**Write-time attribute bound behind a closed key registry (SEC-01).**
Scoria.Observe.Bounds.enforce/2 is now the single write-time choke point every
span attribute payload passes through, immediately after redaction and before both
the operator PubSub broadcast and Postgres persistence. Attribute keys are admitted
only via a closed registry (Scoria.Observe.Semconv.attribute_registry/0), a small
set of vendor prefixes (`gen_ai.`, `server.`, `openai.`, `req_llm.`, `error.`) minus
an exact-key/dot-segment denylist, or host-configured prefixes
(`allowed_key_prefixes`, default `[]`). An unregistered or denied key is **dropped,
never truncated** -- a byte-capped prefix of a leaked prompt is still a leaked
prompt. Admitted values are size-bounded (`max_attribute_bytes`, `max_total_bytes`)
and the attribute map is depth/count/list-length bounded
(`max_depth`/`max_attribute_count`/`max_list_length`); a drop or truncation emits
`[:scoria, :observe, :bounds, :exceeded]` telemetry so an SRE can alert on "my
instrumentation is trying to log prompts." Configure via
`config :scoria, Scoria.Observe.Bounds, ...` -- there is no disable switch, limits
tune upward only.

**Honest SEC-01 scope note.** This bound protects the DURABLE `ai_spans.attributes`
column and the `ReviewerBroadcast` fan-out. It does **not** yet cover streaming
completion text: `[:scoria, :observe, :span, :delta]` chunks are broadcast to the
operator's browser (capped at `max_delta_chunk_bytes` on egress) but never
persisted -- streaming deltas live only in the operator's LiveView process memory
for the duration of the connection.

**New Scoria.Observe.emit_event/1 point-event surface (EVENT-02).** A new
public verb for the closed, 3-atom point-event vocabulary
(`prompt_rendered`, `guardrail_triggered`, `user_feedback_received`) --
`user_feedback_received` is reserved-only for now and has no `lib/`
emitter (that flywheel work belongs to SEED-011 / FB-01). `emit_event/1`
checks the name against the vocabulary up front for a clean bus and a
synchronous `:ok` / `{:error, :unknown_event}` return, and never raises.
The `[:scoria, :observe, :event, :emit]` telemetry handler is the real
boundary of record: it independently re-checks the vocabulary (closing the
raw-bus bypass), redacts through the same single call site spans and
deltas already use, defaults a missing `time` and drops a `nil` `span_id`
before persistence, runs the events through the SEC-01 `Bounds.enforce/2`
tollbooth, and casts to the durable `ai_span_events` table. **Deliberate
v3.6 gap:** a fired `guardrail_triggered` event lands in Postgres with **no
operator UI yet** -- that dashboard surface is Phase 53 D-08 / D-07 future
work, not part of this change.

### Changed

#### Pre-1.0 terminology migration

These notes describe unreleased main-branch changes. Hex release remains `0.1.2` until Phase 50 cuts the next release.

Historical sections below may retain old terminology as history. Current adopter-facing
docs use final vocabulary.

| Previous wording | Final wording | Status |
|------------------|---------------|--------|
| operator persona | reviewer | New docs and dashboard copy use reviewer; `ScoriaWeb.OperatorSurface` remains a legacy alias for `ScoriaWeb.ReviewerSurface`. |
| surface-sense evidence | trace | Run inspection surfaces use trace; RAG/citation evidence remains evidence. |
| verification lane | verification suite | `Scoria.VerificationLanes` remains a legacy alias for `Scoria.VerificationSuites`. |
| projected context | scoped context | `projected_context:` remains accepted as a legacy alias for `scoped_context:`. |
| semantic fast path | semantic cache | `Scoria.SemanticLane`, `lane:`, and `lane_key` remain accepted as legacy aliases for `Scoria.SemanticCache.Profile`, `profile:`, and `cache_key:`. |
| optional knowledge | optional knowledge base | Docs now name the optional retrieval capability as a knowledge base. |

RAG/citation evidence and `evidence_refs` stay unchanged. There is no database migration
for this terminology migration, and legacy aliases remain accepted during the 0.1.x
compatibility window.

## [0.1.2](https://github.com/szTheory/scoria/compare/v0.1.1...v0.1.2) (2026-06-19)


### Features

* **13-01:** add IA component primitives ([eebebcb](https://github.com/szTheory/scoria/commit/eebebcb207e373a9985c6bc12ad77e8b5236b90f))
* **13-02:** implement grouped dashboard nav ([9e0703d](https://github.com/szTheory/scoria/commit/9e0703d9fb1cdd336235cd307b6a30dde763d9e9))
* **13-03:** add honest coming-soon route ([af24726](https://github.com/szTheory/scoria/commit/af24726610f43b2fa7d48281ca8172a0cc67e8a8))
* **13-04:** implement Status Home attention strip ([9401b65](https://github.com/szTheory/scoria/commit/9401b654d3a6a6decea04e583a36aff842d63912))
* **13-05:** add object-aware page headers ([9229aba](https://github.com/szTheory/scoria/commit/9229aba621b6287d7af07f707561eaf39323e6ba))
* **13-06:** add dashboard command palette ([6c3772b](https://github.com/szTheory/scoria/commit/6c3772b47f3f7bfadb65501d26c6bec5bc974b4f))
* **13-07:** thread incident and review ingress links ([3e66229](https://github.com/szTheory/scoria/commit/3e66229df70b9c348a35fd3bb9f17b18dbe9f3b7))
* **13-08:** thread quality loop object links ([d35b92b](https://github.com/szTheory/scoria/commit/d35b92bbcc016ee687799bde3b242c5b6fa8c810))
* **13:** add make seed/reseed + surface demo routes in dev banner ([c3a21e4](https://github.com/szTheory/scoria/commit/c3a21e46419d0c7a84d041071dab9b81d4de8878))
* **14-01:** add Dataset Builder route and navigation ([8d84f0f](https://github.com/szTheory/scoria/commit/8d84f0f960f9b8c4b34938fe1a2f08a51491306c))
* **14-01:** implement Dataset Builder index ([eb4abfd](https://github.com/szTheory/scoria/commit/eb4abfd271034004f494f867abbac28e845f5273))
* **14-02:** convert promote component to shared surfaces ([68cf829](https://github.com/szTheory/scoria/commit/68cf82939d903fa0d169b75ad55849d16a8791bc))
* **14-02:** reconstruct promotion drawer from URL params ([57792b0](https://github.com/szTheory/scoria/commit/57792b0dc3bb44195f74d285a67a38b65859a3c4))
* **14-03:** route review promotion to dataset builder ([9687adf](https://github.com/szTheory/scoria/commit/9687adf59bf3fba4a171a0013efd82d8c0c64a84))
* **14-04:** convert incident evidence to notebook adapter ([959a3b3](https://github.com/szTheory/scoria/commit/959a3b3a1c064490de5ed9f4b1b5b50cc5b6928e))
* **14-04:** convert incidents shell to shared components ([acb9904](https://github.com/szTheory/scoria/commit/acb99042bf34e77280459ec9c3909218210560d1))
* **14-05:** convert eval workbench edit form ([6d106eb](https://github.com/szTheory/scoria/commit/6d106ebcef16474fc61ddc3adcaa84779e40381e))
* **14-05:** convert eval workbench result surfaces ([957c382](https://github.com/szTheory/scoria/commit/957c3827ab926db823fef3b49e99f3da4d392afc))
* **14-06:** convert prompt registry to shared components ([5cebb4b](https://github.com/szTheory/scoria/commit/5cebb4b4e83bdd6a5d575f22a0b1dc5425bdfb28))
* **14-06:** convert release workbench to shared components ([2f655d1](https://github.com/szTheory/scoria/commit/2f655d1006ca21c418c9ff7841d9d1155e11b9a9))
* **15-01:** add shared evidence primitives ([1f15b7f](https://github.com/szTheory/scoria/commit/1f15b7f3c6f0a7a0c98fd0110c1b1329641de44d))
* **15-02:** convert home and runs to shared surfaces ([9c09764](https://github.com/szTheory/scoria/commit/9c09764b59bf66ee105d366db8751c15f99a56d6))
* **15-03:** convert workflow trace inspector surfaces ([8761e85](https://github.com/szTheory/scoria/commit/8761e856320dce509b80829838e93e6b1d92cfe3))
* **15-04:** convert approvals and connectors shared surfaces ([288960a](https://github.com/szTheory/scoria/commit/288960a3f255b6e721f8e2f407f9e6db4fbf763a))
* **15-05:** convert evidence adapters to shared primitives ([8dc3105](https://github.com/szTheory/scoria/commit/8dc3105fb4bb515e122f8a4a7702b8b39ae55570))
* **16-01:** mobile topbar, off-canvas nav drawer markup, and MobileNav JS hook ([433bfb5](https://github.com/szTheory/scoria/commit/433bfb5fd3f4137e2bb204e59c0813597743a255))
* **16-01:** mobile-first shell CSS and drawer motion primitive ([4ccb16b](https://github.com/szTheory/scoria/commit/4ccb16b36c54080e50a40943c95a6adbdb53fe45))
* **16-02:** table/1 overflow viewport, opt-in mobile_summary slot, and aria-sort ([7b1f5f0](https://github.com/szTheory/scoria/commit/7b1f5f0a34cec9fc50f4959bab9b685e70f2967f))
* **16-03:** add named responsive grid split classes to 04-components.css ([7c90246](https://github.com/szTheory/scoria/commit/7c9024608c52fd3b0f09a5c17d7126c7e2b2f838))
* **16-03:** replace all 7 unsupported responsive utility callsites ([dfdf557](https://github.com/szTheory/scoria/commit/dfdf5571f5a8c28eb59753eadb64f6709aa8ed19))
* **16-04:** mobile summaries and domain empty-state copy for Connectors + Dataset Builder ([5005595](https://github.com/szTheory/scoria/commit/5005595804863193e3df30c7708efbdbc629a4f7))
* **16-04:** mobile summaries and domain empty-state copy for Runs + Review Queue ([ff3f960](https://github.com/szTheory/scoria/commit/ff3f9601b61d9990c9a53104fc93a97b8fdf8d16))
* **16-05:** focus-ring overflow-clip-margin, selected-row aria-current, and status tests ([31d65be](https://github.com/szTheory/scoria/commit/31d65be6c8c6d9e3717d522c8883dd181744df0a))
* **16-06:** Phase 16 Playwright parity spec for MOTION-01..04 ([f032ea9](https://github.com/szTheory/scoria/commit/f032ea94d6b2bac0e9c07c4b68256bb433453ebe))
* **16-06:** single-SSOT AA contrast floor guard (D-31) ([238b210](https://github.com/szTheory/scoria/commit/238b2102f5103752741c1ae102e1b204a0d05b10))
* **17-02:** add contact_sheet_index.md + document generator in MAINTAINERS harness section ([361e0f4](https://github.com/szTheory/scoria/commit/361e0f4b0fb365680f7b3ec8e377d77f1ffd84ec))
* **17-02:** add priv/dev/contact_sheet.mjs before/after contact-sheet generator ([c5cc4af](https://github.com/szTheory/scoria/commit/c5cc4af717ae5439de9645d7a815d9601e471137))
* **18-01:** brand-book pressure-test Sections 1-7 with embedded contrast table ([cae5b0a](https://github.com/szTheory/scoria/commit/cae5b0acfd85f633201be85bcd6c1d7b0eec497f))
* **18-01:** zero-dep WCAG 2.1 contrast checker for brand-book pairings ([2b74473](https://github.com/szTheory/scoria/commit/2b7447369b4a0f7345ddb72ae0e94eb06f863f4b))
* **18-02:** append Decisions Locked section with propagation verdict ([030673d](https://github.com/szTheory/scoria/commit/030673d8a80ce83764be5050807b828fb49d7f1f))
* **18-02:** append Sections 8-14 to pressure-test.md ([0de71a8](https://github.com/szTheory/scoria/commit/0de71a883b2279d438fbc0765cbc788c384be2e4))
* **19-01:** geometry + SVG document libraries ([36b0f4c](https://github.com/szTheory/scoria/commit/36b0f4c980136125cc125a01e6536a611bce71dd))
* **19-01:** wordmark + lockup modules + smoke test ([f2cd057](https://github.com/szTheory/scoria/commit/f2cd057e17a5affd589fca0b5a97c669bfc96f7d))
* **19-02b:** round-2 gallery with rejection diagnosis + recommendation ([8a861d7](https://github.com/szTheory/scoria/commit/8a861d70f7e8b95dc148a6b2d2cfc499e3624e73))
* **19-02b:** round-2 lockup-variant toolchain on locked TV-1 mark ([ca13a47](https://github.com/szTheory/scoria/commit/ca13a473e8173a7c411605a42f8c537039a198c9))
* **19-02b:** six round-2 lockup candidates (LK-A..LK-F) ([e62ac68](https://github.com/szTheory/scoria/commit/e62ac6817a7d32b3632a4ef6bdecd9a89b4e49c8))
* **19-02:** build standalone options-gallery.html for gate [#2](https://github.com/szTheory/scoria/issues/2) ([9baa89a](https://github.com/szTheory/scoria/commit/9baa89a22886294a8be803ac6e78210e79ba29b8))
* **19-02:** generate candidate SVGs into candidates/ ([bc70930](https://github.com/szTheory/scoria/commit/bc70930e4853143d3dbcfb6d130e96a528846749))
* **19-02:** hand-tuned logo presets with design-intent blocks ([1dbd26c](https://github.com/szTheory/scoria/commit/1dbd26cd9c0322f93fc294cd3abdf25e2bb51724))
* **19-03:** finalize ranked recommendation block in options-gallery.html ([d0b28ee](https://github.com/szTheory/scoria/commit/d0b28ee98d5e48064940b3b8579275cb95340047))
* **19-03:** LOGO-01..07 + gallery-completeness verifier (verify-logos.mjs) ([8f9f182](https://github.com/szTheory/scoria/commit/8f9f1828c153aed6db1d29b0f61284b130676505))
* **20-01:** converge LK-B/TV-1 into 8 root variant SVGs ([ad487d7](https://github.com/szTheory/scoria/commit/ad487d7c5c877cae30db734e3ae9793935462e32))
* **20-01:** ROOT-* verifier gate + prune galleries & losing candidates ([425a9e1](https://github.com/szTheory/scoria/commit/425a9e1c8c7670cee7189eedc8e9079832baa3f4))
* **20-02:** final-strip.mjs generates standalone final-variants.html confirm strip ([3af3b79](https://github.com/szTheory/scoria/commit/3af3b791a03b9a534895bc3f562d5bd10fea4c17))
* **21-01:** add brandbook/README.md + tools/check-consistency.mjs ([cfa998f](https://github.com/szTheory/scoria/commit/cfa998f7db291a94c7b50e4eb7647b16d4064d1f))
* **21-01:** author brandbook/tokens.css — :root-scoped, --scoria- prefixed, two-tier ([d161748](https://github.com/szTheory/scoria/commit/d16174849b8bdf9a7d61b4cb674dd7d087a9b0b7))
* **21-01:** author brandbook/tokens.json — Threadline-shaped, hex-identical to tokens.css ([02ecc30](https://github.com/szTheory/scoria/commit/02ecc30ee1756cdbca4288e143e0fa3a2d271288))
* **21-02:** author palette/typography/components/terminal example SVGs ([5a9ef0d](https://github.com/szTheory/scoria/commit/5a9ef0d2ed5c3e0b8156b0285b636b936181f376))
* **21-02:** author readme-header/landing-hero/docs-page example SVGs ([7231498](https://github.com/szTheory/scoria/commit/72314988e6d9b44aeb070f7930a10d927bbfbbba))
* **21-03:** build standalone dark-first brand book (index.html) ([44380e6](https://github.com/szTheory/scoria/commit/44380e67bc85fd470dc39b6dad472ac4d2b80565))
* **21-03:** wire brand-book.md into check-consistency (4th hex source) ([55632ec](https://github.com/szTheory/scoria/commit/55632ecae45e6b20b409c57f2303c46b14d92f86))
* **22-01:** dashboard TV-1 mark + favicon wiring (compile-time inline) ([26244d9](https://github.com/szTheory/scoria/commit/26244d9660541f83923d8157625393b8f7eb1235))
* **22-01:** Hex.pm description + GitHub repo description verbatim brand copy (BRAND-08) ([c13899b](https://github.com/szTheory/scoria/commit/c13899be72c3745f98507d551d316945d50b99fb))
* **22-01:** README brand header — picture dark/light lockup, tagline, verbatim opener ([79a2c36](https://github.com/szTheory/scoria/commit/79a2c3615e3d58e597f3600947595edd7f3f58b0))
* **22-02:** GATE.md — dated Phase 22 final quality gate report (all 8 checks PASS) ([2bdbb32](https://github.com/szTheory/scoria/commit/2bdbb3240e7e7a9aa9b03b788b6df8d4a1152f13))
* **22-02:** quality-gate.mjs — 8-check aggregating Phase 22 final gate ([1ffe559](https://github.com/szTheory/scoria/commit/1ffe559f62840b44de8139daa03dde5ae62ec978))
* **23-01:** CACHE-01 — env-scoped cache keys + version-file sourcing ([51c12fe](https://github.com/szTheory/scoria/commit/51c12fe05636b1f90d61072bb02e7b15e780fa5d))
* **23-01:** CACHE-02 — build-once job + artifact restore + 3 contract assertions ([5f606f1](https://github.com/szTheory/scoria/commit/5f606f1dd79f2c53488df7e1ecf676dfb375dfad))
* **24-01:** add knowledge lane contract test (D-03 coverage ratchet) ([a4dd664](https://github.com/szTheory/scoria/commit/a4dd6643e7e85ec9b7994100b6a03954dcc50acb))
* **24-01:** scope knowledge lane to --only knowledge, add accessor and after_suite guard ([dcbb535](https://github.com/szTheory/scoria/commit/dcbb53581487b540d33103aae5d1956e3399203f))
* **25-01:** refactor ci_policy_contract_test.exs to parallel-shape + derived fan-in completeness; fold WR-03 ([5cb9613](https://github.com/szTheory/scoria/commit/5cb961380bc4df5edb5d911460057a32370ef429))
* **25-01:** restructure ci-verify.yml into parallel sibling jobs + verify-summary fan-in ([84103dc](https://github.com/szTheory/scoria/commit/84103dc7a86f76bc1d03898dd4086b18bc8f6a1a))
* **25-01:** split verification_lanes_test.exs ci lane ordering into intra-vs-cross parallel-shape asserts ([f418f64](https://github.com/szTheory/scoria/commit/f418f64d725f968218459517abe682074771f625))
* **26-01:** shard full ExUnit suite into 4-way GHA matrix job (SHARD-01) ([2106758](https://github.com/szTheory/scoria/commit/210675880f41838d8884de3585b129f06d2622c6))
* **27-01:** add durable contract guards — ephemeral-port ban, no-TEMP-step, no-retry-on-test-workflows ([4b884c8](https://github.com/szTheory/scoria/commit/4b884c8f66a1998943aa4a44c5d1ad3fb7e09525))
* **28-01:** implement Mix.Tasks.Scoria.Ci merge-gate task + ci alias ([f9826b3](https://github.com/szTheory/scoria/commit/f9826b3bfa569b977f6039ff280d7a12a931827b))
* **28-03:** make ratchet warning capture compile-only + parity guard ([bf15f10](https://github.com/szTheory/scoria/commit/bf15f1056d65e828e32553dca870c22aac791b9c))
* **29-01:** thread PORT 4799 through dev harness (DXCLI-01) ([b4e8b3d](https://github.com/szTheory/scoria/commit/b4e8b3d56a9d4b07b05dc7e248675d796b7ed34b))
* **30-01:** add native startup URL line to Makefile dev: recipe ([0f058b9](https://github.com/szTheory/scoria/commit/0f058b930d01d83cbfc1747ba6225e570776e558))
* **30-01:** update Docker dev banner with live route list, Traefik link, native notice ([050709f](https://github.com/szTheory/scoria/commit/050709fb0e7e5d52a56f033be9f7ff1f2879be40))
* **31-01:** add Dockerfile.dev boundary invariant comment + docs layer-invalidation table ([9bb2eaa](https://github.com/szTheory/scoria/commit/9bb2eaa753ab8f9f036fdbd4ba25ce9536a732d4))
* **32-01:** add safe 1Password secret examples ([4a3a558](https://github.com/szTheory/scoria/commit/4a3a558d522ccfc909c9cd12bde47a36d6390201))
* **34-02:** extend post-publish port scanner ([5ebaae2](https://github.com/szTheory/scoria/commit/5ebaae293b5d296f92262267c47620c490968497))
* **ui:** dark/light/system theme picker + pre-paint FOUC fix ([269d82a](https://github.com/szTheory/scoria/commit/269d82a90456c77cba8cbea1adbc1edf1e9e877b))
* v2.17 brand system, dashboard IA, theme picker + dev DX ([#9](https://github.com/szTheory/scoria/issues/9)) ([1d2c9e2](https://github.com/szTheory/scoria/commit/1d2c9e2f773e9687be7a6fd53cbd71a96e66980b))


### Bug Fixes

* **13:** default dev dashboard to demo tenant + seed full IA demo data ([1f05019](https://github.com/szTheory/scoria/commit/1f050193fe8d376af066e044d1799920744c6d03))
* **13:** revise orientation spine plan copy ([b576066](https://github.com/szTheory/scoria/commit/b5760662450e54af3bf58c35942748af36ea098f))
* **13:** revise orientation spine plans based on checker feedback ([51698fe](https://github.com/szTheory/scoria/commit/51698fea4cfd8a8ce5e06219cf3aed87ad039049))
* **14-02:** normalize promotion key links ([ca48f4a](https://github.com/szTheory/scoria/commit/ca48f4a78e14be31ed1a12d8e0e3f19388803110))
* **14:** align support gallery smoke with status home IA ([0bf47c7](https://github.com/szTheory/scoria/commit/0bf47c7a5478649bd7a9b3fbdff614dba4f5080d))
* **14:** cite missing plan decisions ([2f704d4](https://github.com/szTheory/scoria/commit/2f704d488cef5a588572e83607d4692b0660ba11))
* **14:** review queue back-link honors scoria_base mount path ([04f3ac5](https://github.com/szTheory/scoria/commit/04f3ac57113595d9ebf7f6e120a25c49337c9030))
* **14:** revise plans based on checker feedback ([33f82a1](https://github.com/szTheory/scoria/commit/33f82a1a1ff9c61abe89cdfcdcfa0c9b40f57243))
* **15-review:** gate table density controls ([0fc2ff7](https://github.com/szTheory/scoria/commit/0fc2ff75cc747246a825e7010e7f96c062f60643))
* **15-review:** gate table sort controls ([b23f530](https://github.com/szTheory/scoria/commit/b23f530db6ad7b1dc4d2f6097e72d20983349ccc))
* **16-01:** modern HEEx comment syntax (&lt;%!-- --%&gt;) in mobile shell ([f01d8b0](https://github.com/szTheory/scoria/commit/f01d8b0d86f5ad06ceb9db0998eae62bb0d4b7cd))
* **16:** address code review — style mobile summary cards (CR-01) + dataset crash guard (WR-06) ([b67087d](https://github.com/szTheory/scoria/commit/b67087d0f90cc425316b0ca36415b17d648021c3))
* **16:** regenerate committed dashboard asset bundle from phase-16 source ([0ca184c](https://github.com/szTheory/scoria/commit/0ca184c7736c8a410d34061b7a49e6ac93f9b06a))
* **17-02:** IN-02 remove unused fileURLToPath import ([ba62be1](https://github.com/szTheory/scoria/commit/ba62be112798797622b8ea4fe66c915a8f96e2ca))
* **17-02:** IN-03 update stale .gitignore rationale comment ([71ca01a](https://github.com/szTheory/scoria/commit/71ca01a3dd993242904a73b8fb7e3c5989d2256c))
* **17-02:** WR-01 HTML-escape interpolated values; IN-01 drop dead isBaseline param ([e5576f2](https://github.com/szTheory/scoria/commit/e5576f21fc3d41554f8f096ce4ab971b9928a3dc))
* **17-02:** WR-02 URL-encode img src path segments ([3899a44](https://github.com/szTheory/scoria/commit/3899a4457c45f67fe31fa2f84f9909d15a3ee997))
* **17-02:** WR-03 use stat-based directory checks instead of existsSync ([ae2dbbe](https://github.com/szTheory/scoria/commit/ae2dbbeb4ee1935ccdeb7f7b0345874efa194f78))
* **27-01:** FLAKE-01+02 — fix Postgres host port to 5432 in all 5 CI blocks, delete TEMP e2e step ([5277e90](https://github.com/szTheory/scoria/commit/5277e906b4210bfb9efb59584e656bb025494f42))
* **27-01:** harden ephemeral-port guard against quoted binds; align topology comments ([fb73f8e](https://github.com/szTheory/scoria/commit/fb73f8e6bc1dda0a75f8cdf8699f681f5700601f))
* **28-03:** give scoria.install_check tests 180s timeout for CI shard load ([06cdc34](https://github.com/szTheory/scoria/commit/06cdc343e7d4a6f97623d4238bb22426e43494f9))
* **28-03:** ratchet lane needs Postgres; update CI policy contract ([8501578](https://github.com/szTheory/scoria/commit/85015787061811ca67896c53926e2ffcac226c56))
* **28-03:** repair parallelized CI topology for its first real run ([d07093b](https://github.com/szTheory/scoria/commit/d07093b426d855ce2bcc22b5322eb29af2ceb9c4))
* **28:** revise plans based on checker feedback ([a83f5be](https://github.com/szTheory/scoria/commit/a83f5be2610ddeea615a2091e03f01da90539458))
* **33:** mark research questions resolved ([0695a29](https://github.com/szTheory/scoria/commit/0695a297c8dcd8075a6fe69b0610b390703f30ab))
* **33:** revise plans based on checker feedback ([d8dcc24](https://github.com/szTheory/scoria/commit/d8dcc2420fdbf3c5f2503aa4689605dd52c801c3))
* **34-02:** fix post-publish postgres port bind ([8675672](https://github.com/szTheory/scoria/commit/867567283eed68b0d0994dfe53f3931cd5449e59))
* **34:** close code review doc guard gaps ([8d981f5](https://github.com/szTheory/scoria/commit/8d981f5705906bd59e4757fb37ae8836d723321a))
* **34:** pin ci e2e flake guard coverage ([91ff82d](https://github.com/szTheory/scoria/commit/91ff82db3fd1cf7975c242db4b0808c00eaa247e))
* **34:** revise plans based on checker feedback ([fab3308](https://github.com/szTheory/scoria/commit/fab33085527d050100570d5c49c5e7e60b11b59d))
* **35-01:** encode previous-live registry lineage ([fbb5e2d](https://github.com/szTheory/scoria/commit/fbb5e2d805c68e06e8dd10dbf4ccb01c3e810eab))
* **35-02:** align release branch e2e gate ([4099118](https://github.com/szTheory/scoria/commit/409911815c903842daf509b00ed1d5d5364b327f))
* **35-02:** clear release docs warning gate ([532cc4c](https://github.com/szTheory/scoria/commit/532cc4c1b869e761346a7ea22e0e3d8e785cbb45))
* **35-02:** include Docker DX policy surfaces for release CI ([1b74283](https://github.com/szTheory/scoria/commit/1b74283ce264032559aa35c056b5c4070dc2344b))
* **brandbook:** §3 logo display bugs — mono use-viewport mapping, subtitle colorway panel, mark on both grounds ([0efefb5](https://github.com/szTheory/scoria/commit/0efefb5e56d88464acdbaa3790463065fb85d015))
* **dev:** use the standard DB pool in dev (off the test Sandbox) ([3249c6e](https://github.com/szTheory/scoria/commit/3249c6e1b07f84a06765b917c47b1f8c36349f31))
* **ui:** drawer/modal scrim no longer intercepts panel clicks ([b77970b](https://github.com/szTheory/scoria/commit/b77970b64fcd4aa40a1a24ce8de27ed54a5d6ed8))

## Historical main-branch notes

### Added

- Self-contained, dark-first (with light theme) operator dashboard design system. The
  `/scoria` dashboard now ships its own brand-token CSS, client bundle (LiveSocket +
  hooks), and self-hosted fonts (IBM Plex Sans, JetBrains Mono) — it renders fully styled
  and interactive with **no dependency on the host app's Tailwind/asset pipeline**.
- Task-oriented navigation shell: persona-grouped sidebar (Operate / Improve), breadcrumb
  topbar, light/dark theme toggle, and a GOV.UK-style "what do you want to do?" task band
  on the Live Ops landing page.
- Runs index at `/scoria/workflows`; the previously-unreachable Eval Workbench is now
  routed at `/scoria/eval_specs`.
- Routed Operate pages extracted from the Live Ops god-page, each a focused, linkable
  surface with its own nav item: Approvals (`/scoria/approvals` — inbox + decision modal),
  Connectors (`/scoria/connectors` — runtime + connector fleet posture and drawers), and
  Incidents (`/scoria/incidents` — tenant SRE triage with trace-first evidence).
- `?tenant=` view parameter on Live Ops and `priv/repo/dev_seed.exs` (gallery) to populate
  every dashboard screen with realistic data.
- `$ mix scoria.assets.build` to (re)generate the shipped dashboard asset bundle.
- First-run empty states on the Prompt Registry (`/scoria/prompts`) and Eval Workbench
  (`/scoria/eval_specs`) tables, consistent with the Runs and Incidents pages.

### Changed

- `$ mix scoria.install` no longer probes or edits the host app's Tailwind config. Because the
  dashboard ships self-contained assets, install is now router mount + Ecto migrations +
  runtime config only — there is no Tailwind install surface and no host asset work.

- Live Ops (`/scoria`) slimmed to a task band + live trace stream plus a compact
  Approvals/Connectors/Incidents "at a glance" strip that links to the new routed pages;
  approvals, fleet posture, and the tenant incident rollup moved off the landing page.
- Shared `ScoriaWeb.OperatorSurface` read model now backs Live Ops and the routed Operate
  pages, replacing the duplicated fleet/SRE projection reads.
- Status→color styling fully consolidated into `ScoriaWeb.UI` (`tone/1` + `<.badge tone=>`
  + `<.flash_group>`); the per-component `badge_class/status_color/trace_badge_class/
  flash_kind_class` helpers are removed and a drift-guard test prevents their return.
- Bump `req_llm` peer dependency to `~> 1.13` (locked at 1.13.0)

## 0.1.1 (2026-05-30)

### Added

- Shared SupportJourney handlers for overlay and gallery journey smokes
- Support copilot gallery optional lane journeys: semantic FAQ, knowledge, connector
- Gallery producer-path orchestrator smoke on `/scoria`
- `docs/MAINTAINERS.md` for CI topology and release operations
- `docs/connector_adoption.md` in Hex package and docs extras
- Named remote connector adoption lane (`$ mix test.connector`) with SupportJourney billing fixture proof

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

## Historical main-branch notes before 0.1.0

## [0.1.0]

First public Hex packaging of Scoria's in-repo capability through the v2.6 warning-ratchet
closeout. Integrators get a Phoenix-native runtime with durable runs, bounded escalation,
optional semantic reuse, and executable adoption lanes — without adopting internal planning
milestone names as product releases.

### Added

- **Default runtime** — identity-aware durable runs, approvals, and operator evidence via
  `Scoria.start_run/2`, `Scoria.resume_run/2`, and `/scoria` inspection surfaces; prove with
  `$ mix scoria.test.adoption`.
- **Bounded handoff** — narrow same-run delegation with projected context and visible lineage
  through `Scoria.start_handoff_run/3`; prove with `$ mix scoria.test.runtime_to_handoff`.
- **Semantic fast path** — tenant-scoped reuse for explicitly safe read-only lanes via
  `Scoria.SemanticLane`; prove with `$ mix scoria.test.semantic_fast_path`.
- **Optional knowledge** — pgvector-backed retrieval when chosen; prove with
  `$ mix scoria.test.knowledge`.
- **Upgrade-safe install** — planner/check/apply paths via `$ mix scoria.install --dry-run`,
  `$ mix scoria.install --check`, and `$ mix scoria.install`.
- **Maintainer CI trust** — warning baseline and ratchet enforcement, policy→test topology
  guarded by contract tests, and local parity via `$ mix scoria.test.ci_trust` (maintainer-only;
  not an adopter integration requirement).

### Roadmap traceability

| Planning tranche | Shipped | Reference |
|------------------|---------|-----------|
| v2.1 | 2026-05-25 | `.planning/MILESTONES.md#v21-tenant-scoped-semantic-fast-path` |
| v2.3 | 2026-05-27 | `.planning/MILESTONES.md#v23-runtime-to-handoff-adoption-example` |
| v2.4 | 2026-05-27 | `.planning/MILESTONES.md#v24-adoption-reliability-contract` |
| v2.5 | 2026-05-27 | `.planning/MILESTONES.md#v25-installer-safety--upgrade-confidence` |
| v2.6 | 2026-05-28 | `.planning/MILESTONES.md#v26-warning-ratchet` |
