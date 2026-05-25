# Bounded Handoff Productization Lessons

*Captured on 2026-05-24 after the post-`v1.9` bounded handoff and support-truth pass.*

## 1. Public handoffs should stay narrow

Scoria already had durable handoff substrate inside `Scoria.Workflows`. The highest-leverage move was not broader multi-agent surface area; it was a thin public lane that starts a bounded delegated run through `Scoria` itself.

Implication for future work:
- prefer public facades that compound existing durable seams
- avoid reopening platform-shaped orchestration design unless adopter demand clearly exceeds the current bounded lane

## 2. Projected context is the real product boundary

The useful adopter story is not "Scoria can hand work to another role." The useful story is "Scoria can hand work to another role with explicit, inspectable, least-privilege context."

Implication for future work:
- treat projected-context defaults and unsafe-key rejection as first-class product behavior
- keep operator evidence and runtime DTOs legible enough that delegated lineage can be inspected without reading internal workflow rows directly

## 3. Support truth is part of productization, not cleanup fluff

The user-facing value of bounded handoffs depended on the docs, examples, and verification lane telling the same story as the code. Fixing `mix test.adoption` env defaults and removing missing-module drift from the normal compile/test path were part of the milestone value, not incidental polish.

Implication for future work:
- bundle public API work with install/docs/verification alignment in the same wedge
- treat maintainer proof lanes as part of the product surface for OSS adoption

## 4. Thin shims are sometimes the right boundary move

Some connector and compaction surfaces were already referenced by normal compile paths but lacked stable module shells. Adding narrow read-model/controller/component/tokenizer shims was cheaper and more honest than leaving the repo to emit avoidable missing-module warnings in default flows.

Implication for future work:
- if a surface is visible in the default product path, either ship a narrow stable shell or gate it more explicitly
- do not leave half-wired modules leaking uncertainty into the boring-adoption lane

## 5. The next milestone should not re-research handoffs

The repo now has a real public bounded handoff API, guide, and source-backed adoption checks. The next milestone decision should start from that truth rather than treating handoffs as an open research candidate again.

Implication for future work:
- if a formal milestone is opened around this work, keep it verification/closeout-oriented
- otherwise shift the next net-new capability decision to what remains after bounded handoffs, not before them
