# Phase 26 Verification

**Status:** pass
**Score:** 7/7 must-haves verified

## Goal Achievement
The primary goal of Phase 26 (Release Gates and Approvals) was to insert a human-in-the-loop release gate before a draft prompt template is promoted to active. This has been fully achieved.
- Draft templates can now trigger a release request using the `Scoria.Workflows.PromptRelease` workflow.
- Operators can view a comparison deck showing eval performance for both the draft and active templates in `ReleaseWorkbenchLive`.
- The workbench allows requesting release and then approving or rejecting the pending approval block.
- A `Scoria.Runtime.ReleaseGate` middleware intercepts requests and explicitly defaults to the active prompt template unless an override is provided, enforcing the gating mechanism at runtime.

## Verification

### Automated Verifications
1. **Runtime falls back to the active prompt version if `prompt_version` is omitted.** - Verified by `ReleaseGateTest`.
2. **Explicit requests for a draft version fail if `X-Scoria-Role` lacks testing permissions.** - Verified by `ReleaseGateTest`.
3. **Workflow can request approval for a draft prompt release.** - Verified by `PromptReleaseTest` and manual testing in the workbench test.
4. **Workflow can process an approval, promoting the draft to active and gating future invocations.** - Verified by `PromptReleaseTest`.
5. **Operator can explicitly approve the draft using Scoria's workflow system, promoting it to active and gating future invocations.** - Verified by LiveView test updates handling `request_release`, `approve_release`, and `reject_release`.
6. **Operator can view a comparison of draft vs active metrics in an embedded UI.** - Verified by `ReleaseWorkbenchLiveTest` (deck renders metrics dynamically).
7. **Operator can approve or reject the draft directly from the UI.** - Verified by `ReleaseWorkbenchLiveTest` (LiveView correctly interacts with `PromptRelease` module).

### Human Verification Required
None. Automated tests cover the full flow.
