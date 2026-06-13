---
phase: 17-consistency-sweep-proof
reviewed: 2026-06-13T00:00:00Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - priv/dev/contact_sheet.mjs
  - lib/scoria_web/ui.ex
  - priv/shots/.gitignore
findings:
  critical: 0
  warning: 4
  info: 3
  total: 7
status: issues_found
---

# Phase 17: Code Review Report

**Reviewed:** 2026-06-13T00:00:00Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Reviewed the three Phase 17 files. As scoped, `lib/scoria_web/ui.ex` changes are
documentation-only (`@doc` expansions, no behavior change) and `priv/shots/.gitignore`
is config — both verified clean of behavioral defects. All substantive findings are in
`priv/dev/contact_sheet.mjs`, a dev-only Node generator that emits an HTML before/after grid.

No BLOCKER-tier issues. The script is dev-only (run manually by maintainers, not network-
exposed, no untrusted input crossing a trust boundary), so the HTML-injection class of issue
is rated WARNING rather than Critical: the inputs (CLI dir args, on-disk PNG filenames) are
maintainer-controlled. However, the complete absence of HTML escaping and URL encoding is a
real correctness defect — benign-but-legal filenames (containing `&`, `<`, spaces, `#`, `?`)
silently corrupt the generated sheet, which directly undermines the visual-proof purpose of
the artifact. These should be fixed.

## Warnings

### WR-01: No HTML escaping on any interpolated value — output corruption / injection

**File:** `priv/dev/contact_sheet.mjs:106,110,117,318,319` (and header block 230-329)
**Issue:** Every dynamic value is interpolated raw into the HTML template with no escaping.
The highest-risk vectors are the on-disk PNG `filename` and the CLI-supplied directory labels:

- `td.filename` (line 117): `<td class="filename">${filename}</td>` — a filename containing
  `<` or `&` renders as broken/partial markup.
- `alt` attribute (lines 106, 110): `alt="Before: ${filename}"` — a filename containing a
  double-quote (`"` is legal on macOS/Linux) terminates the `alt` attribute early and can
  inject arbitrary attributes/markup into the `<img>` tag.
- Header labels (lines 318-319): `${beforeLabel}` / `${afterLabel}` come straight from
  `--before` / `--after` argv with no escaping.

Because `filename` originates from `readdir` of an arbitrary directory the maintainer points
at, a file literally named `"><img src=x onerror=alert(1)>.png` would inject executable markup
into the opened HTML. Dev-only context keeps this out of BLOCKER range, but it is a correctness
defect even for fully benign inputs (`&`, `<`, `>` are valid in filenames).
**Fix:** Add an escaper and apply it to all text/attribute interpolations:
```js
function escapeHtml(s) {
  return String(s).replace(/[&<>"']/g, (c) => (
    { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]
  ));
}
// usage:
`<td class="filename">${escapeHtml(filename)}</td>`
`alt="Before: ${escapeHtml(filename)}"`
`<strong>Baseline dir:</strong> ${escapeHtml(beforeLabel)}`
```

### WR-02: Image `src` paths not URL-encoded — broken images for legal filenames

**File:** `priv/dev/contact_sheet.mjs:97-99,106,110`
**Issue:** `relPath()` returns a raw filesystem path that is placed directly into
`src="${beforeSrc}"`. Filenames or directory components containing characters that are
significant in URLs — space, `#`, `?`, `%`, `&` — are interpreted by the browser as URL
syntax, not literal path characters. A capture named `populated_live ops.png` or any dir
with a `#` in its name resolves to the wrong URL and the image silently fails to load,
defeating the visual-proof purpose. (This is distinct from WR-01: escaping `&` to `&amp;`
fixes the HTML attribute, but the browser still URL-decodes the value, so the path component
itself must be percent-encoded.)
**Fix:** Encode each path segment before joining for the URL:
```js
function relUrl(outFile, targetFile) {
  const rel = relative(dirname(outFile), targetFile).replace(/\\/g, '/');
  return rel.split('/').map(encodeURIComponent).join('/');
}
// then escape the result for the HTML attribute as well (WR-01)
const beforeSrc = beforeFile ? escapeHtml(relUrl(outPath, beforeFile)) : null;
```

### WR-03: TOCTOU between `existsSync` and `readdir` / partial-dir crash surface

**File:** `priv/dev/contact_sheet.mjs:79-91,162-169,185`
**Issue:** `listScreenPngs` guards `readdir` with both `existsSync` and a try/catch, so it
degrades gracefully. But `main()` guards `before`/`after` with bare `existsSync` (lines
162-169) and `afterDirMissing` re-stats with `existsSync(join(after, screen.name))` (line
185) — a path that exists as a *file* (not a directory) passes `existsSync` and would then
fail in `listScreenPngs`'s `readdir` (caught, returns `[]`, so it silently reports "0 before
/ 0 after" rather than erroring). The behavior is non-fatal but misleading: a regular file
at a screen path is reported as an empty/missing screen rather than flagged.
**Fix:** Prefer `statSync(p).isDirectory()` (wrapped) over `existsSync` for the directory
checks, or at minimum surface a warning when a screen path exists but is not a directory,
so maintainers are not misled by a silent "0 / 0" line.

### WR-04: `--out` directory not ensured before `writeFile`

**File:** `priv/dev/contact_sheet.mjs:331`
**Issue:** `writeFile(out, html)` is called with no guarantee that `dirname(out)` exists.
If a maintainer passes `--out reports/2026/sheet.html` and `reports/2026/` does not exist,
`writeFile` rejects with `ENOENT`. This is caught by the top-level `.catch` (line 335) so it
fails loudly rather than corrupting data — acceptable, but the error (`ENOENT, open ...`) is
opaque relative to the script's otherwise-friendly validation messages.
**Fix:** Either `mkdir(dirname(out), { recursive: true })` before writing, or add an explicit
pre-check mirroring the `--before`/`--after` validation:
```js
import { mkdir } from 'fs/promises';
await mkdir(dirname(out), { recursive: true });
await writeFile(out, html, 'utf8');
```

## Info

### IN-01: Dead parameter `isBaseline` in `renderPairRow`

**File:** `priv/dev/contact_sheet.mjs:101,133`
**Issue:** `renderPairRow(filename, beforeFile, afterFile, outPath, isBaseline, isAfterMissing)`
declares `isBaseline` but never references it in the body. The only call site (line 133)
hard-codes `false`. Dead parameter — easy to misread as meaningful.
**Fix:** Remove the `isBaseline` parameter and the `false` argument at the call site.

### IN-02: Unused import `fileURLToPath`

**File:** `priv/dev/contact_sheet.mjs:19`
**Issue:** `import { fileURLToPath } from 'url';` is never used anywhere in the file
(no `import.meta.url` resolution is performed).
**Fix:** Remove the unused import.

### IN-03: Stale `.gitignore` rationale comment

**File:** `priv/shots/.gitignore:11-12`
**Issue:** The comment states "gap_register.md is tracked because it is the committed
baseline audit output" and implies it is the only committed `.md`. In fact
`gap_register_final.md` and `contact_sheet_index.md` are also tracked (verified via
`git ls-files priv/shots/`) and are not mentioned. The negation `!gap_register.md` works
correctly (gap_register lives at the top level, not under a `*/` subdir, so it is reachable),
but the rationale comment understates which files are committed.
**Fix:** Update the comment to enumerate all committed top-level docs, or generalize the
note to "top-level `.md` audit outputs are tracked; date-stamped subdirs and PNG/JSON/HTML
artifacts are ignored."

---

_Reviewed: 2026-06-13T00:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
