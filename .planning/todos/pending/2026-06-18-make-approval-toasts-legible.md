---
created: 2026-06-18T16:56:06.447Z
title: Make approval toasts legible over dense UI
area: ui
resolves_phase: 38
files:
  - assets/css/04-components.css:1120
  - /Users/jon/Desktop/Capture d’écran 2026-06-18 à 12.47.16 PM.png
---

## Problem

The approval rejection toast can render over the approvals list with a translucent warning background, making the message hard to read against the table rows underneath. The captured example shows `Approval rejected — workflow remains paused.` overlapping pending approval rows and the text competing with the underlying `Pending` badges and `Inspect approval` buttons.

This is a small UI polish issue and should not distract from the current phase work, but it should be followed up later because approval feedback needs to be readable at the moment an operator makes a decision.

## Solution

Treat this as a focused toast legibility pass:

- Reproduce the warning/error approval toast on `/scoria/approvals`, ideally using an approval rejection path.
- Verify whether `.scoria-toast--warn` or its tone tokens still use a translucent background over dense content.
- If reproducible, make warning/error toast backgrounds effectively opaque while preserving Scoria tone colors, border contrast, and close-button usability.
- Add an automated regression, preferably visual or DOM-level, that places a warning toast over the approvals table and proves it remains readable.

Acceptance:

- Approval rejection toast text is readable over approval rows in both dark and light themes.
- Toast background is not transparent enough for row text/buttons to impair readability.
- Regression covers the approval toast over a dense approval-list backdrop.
- Scope stays limited to toast legibility; approval workflow state transitions and decision semantics are unchanged.
