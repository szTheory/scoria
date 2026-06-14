---
id: theme-fouc-system-picker
title: "Theme FOUC fix + dark/light/system picker (replace binary Theme toggle)"
status: pending
created: 2026-06-13
priority: low
resolves_phase: null
tags: [ui, theme, fouc, dx]
source: "Surfaced during Phase 13 UAT (Test 1, Status Home) — user in light mode saw the dashboard flash dark before settling to light; explicitly deferred, not a Test 1 failure."
---

## Why this exists

During Phase 13 UAT, the user (in light mode) observed the dashboard **flash dark before
loading light** on initial page load — a theme flash-of-unstyled-content (FOUC). They also
asked to **replace the single "Theme" toggle button with a dark / light / system picker**,
suspecting the flash is tied to system mode. Explicitly deferred ("don't have to worry about
that right now") — captured here for a future UI polish pass.

## Root cause (confirmed during UAT research)

The page paints dark first, then JS switches it to the stored preference:

1. `lib/scoria_web/components/layouts/root.html.heex:2` hardcodes
   `<html ... class="scoria-root" data-theme="dark">`.
2. `assets/css/02-tokens.css:14` makes dark the CSS default (`.scoria-root { color-scheme: dark; ... }`);
   light is only applied via `.scoria-root[data-theme="light"]` (~lines 169–231).
3. The stored preference (`localStorage["scoria-theme"]`) is only read/applied when the
   `Hooks.ThemeToggle` LiveView hook mounts — which runs **after** first paint
   (`assets/js/scoria.js:40-52`).

So a light-mode user gets: parse `data-theme="dark"` → paint dark → JS hook mounts → reads
localStorage → sets `data-theme="light"` → repaint light (the visible flash).

There is **no `prefers-color-scheme` handling** anywhere in CSS or JS today, and the toggle is
strictly binary (dark/light) — no "system" mode.

## Fix direction (for later — do NOT implement now)

1. **Kill the flash:** add a tiny **pre-paint inline `<script>`** in `root.html.heex` (in
   `<head>`, before body content / before any CSS-driven paint) that reads
   `localStorage["scoria-theme"]`, falls back to
   `window.matchMedia("(prefers-color-scheme: dark)")`, and sets `data-theme` on `<html>`
   **before** first paint. (Must respect the existing CSP nonce — see
   `assigns[:scoria_nonce]` usage at `root.html.heex:13`.)
2. **Add system mode / picker:** replace the binary `Hooks.ThemeToggle` button — mobile at
   `app.html.heex:18-26`, desktop at `app.html.heex:125-134`, hook at `scoria.js:40-52` — with a
   **dark / light / system** picker. Persist the chosen mode; when `system`, resolve via
   `prefers-color-scheme` and react to OS changes (`matchMedia(...).addEventListener("change", ...)`).
3. Keep `data-theme` as the single source of truth on `<html>` so the existing token CSS keeps
   working unchanged.

## Acceptance

- Light-mode (and system-light) users see **no dark flash** on load — the correct theme is set
  before first paint.
- Theme control offers **dark / light / system**; `system` follows the OS and updates live when
  the OS theme changes.
- Choice persists across reloads; CSP nonce respected on any inline script.
