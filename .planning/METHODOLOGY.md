# Project Methodology

## Decisive Defaults

**Diagnoses:** Repeated low-impact implementation questions in areas where Scoria already has a stable product posture, codebase precedent, or ecosystem-default answer.

**Recommends:** Prefer the Scoria-recommended default after codebase-first analysis instead of escalating every choice to the user. Bias toward:
- one obvious Phoenix/Ecto/Oban path
- durable truth over clever projection-only state
- explicit identity and policy propagation
- boring embedded-library ergonomics over hosted-platform flexibility

Only interrupt the user when a decision changes one of these:
- product shape
- security or policy boundary
- durable truth model
- tenant blast radius
- materially different operator UX or spend semantics

**Apply when:** Discussing or planning phases where multiple technically valid options exist, but most differences are implementation-level rather than strategic. Especially apply for naming, schema decomposition, queueing mechanics, retry wiring, projection layout, and other defaults that should be shifted left unless they alter Scoria's contract with operators or host apps.
