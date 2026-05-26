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

## Research-First Escalation

**Diagnoses:** Premature questioning before Scoria has exhausted repo context, prompt-corpus guidance, established ecosystem conventions, and obvious prior-art comparisons.

**Recommends:** Before asking the user to choose among implementation directions:
- read the relevant phase artifacts, prior CONTEXT/RESEARCH files, and prompt-corpus materials under `prompts/` when they shape product posture or DX
- inspect current code and task surfaces to see whether the repo already implies a preferred answer
- compare serious alternatives against idiomatic Phoenix/Plug/Ecto/LiveView library conventions and strong adjacent OSS prior art
- return one cohesive recommendation set, not a menu, unless there is no clear winner after research

Only escalate after this research pass, and then only for decisions that materially affect:
- product shape
- security or approval boundary
- durable truth or migration contract
- tenant blast radius
- externally visible operator or adopter workflow in a way that has no clear superior default

**Apply when:** Discussing or planning phase gray areas, especially docs/support truth, public command naming, installer behavior, verification lanes, and other adopter-facing seams where least surprise and ecosystem coherence matter more than preserving every historical option.
