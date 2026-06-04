# Design-System Gap Register — Baseline 2026-06-04

## Summary
- Screens audited: 9
- P0 issues (score 1): 0
- P1 issues (score 2): 11
- Passing (score ≥ 3): 71

## Ranked Findings (worst first)

### all-screens (flash) — consistency: 2/5
> flash_tone_class/1 (lib/scoria_web/ui.ex) renders flash banners with raw palette classes (border-rose-200 bg-rose-50 text-rose-900) instead of semantic design-system tokens. Not captured visually (no active flash in the baseline shots). Known DS-05 gap — fix in Phase 12, not Phase 11.
### connectors — density: 2/5
> Empty states consume significant vertical space with minimal information
> Large amounts of unused dark space in main content area
> Navigation sidebar is appropriately dense
> Two-column layout is good use of horizontal space when populated
> Current empty state view feels sparse - would benefit from onboarding CTAs or additional guidance to fill space productively
### eval_specs — a11y: 2/5
> Cannot verify focus-visible states from static screenshot
> Low contrast between table content and dark background may not meet WCAG AA
> Text appears to be light gray on dark background - contrast ratio unclear
> Active state relies heavily on color (ember background) without additional indicator
> Navigation icons should have accessible labels (not verifiable from screenshot)
### eval_specs — density: 2/5
> Large amount of empty space below the 2-row table - viewport underutilized
> Table could accommodate more rows or additional information per viewport area
> Sidebar navigation has appropriate density with clear grouping
> Main content area feels sparse with minimal data presentation
> Significant vertical space wasted for an information-dense operator dashboard
### eval_specs — responsive: 2/5
> Fixed sidebar navigation would likely cause issues at 375px mobile width
> Table with 4 columns (Name, Version, Description, Actions) would be difficult to display on mobile
> No visible mobile navigation pattern or hamburger menu
> Layout appears optimized for desktop (1280px+) only
> Breadcrumb navigation at top may wrap or break on narrow viewports
### prompt_release — a11y: 2/5
> Dark background with light text meets contrast requirements
> Table structure appears semantic with proper headers
> Status column uses both color and text ('draft', 'active') - good
> Cannot verify focus-visible states on interactive elements from screenshot
> Edit links lack visible affordance which impacts keyboard navigation discoverability
> No obvious ARIA labels or screen reader considerations visible
> Icon-only navigation items may lack text alternatives
### prompt_release — density: 2/5
> Table has only 2 rows visible with significant empty space below
> Screen real estate not efficiently used - large areas of unused dark space
> Table row height generous but not excessive
> Sidebar width appropriate for navigation labels
> Critical: viewport shows ~20% content, 80% empty space
> Could display more rows or provide additional context/controls
> Empty state not shown - unclear if this is all data or pagination needed
### prompt_release — responsive: 2/5
> Layout appears optimized for desktop viewport (1280px+)
> Fixed sidebar would likely cause issues on mobile (375px)
> Table with 5 columns would require horizontal scroll on mobile
> No visible responsive breakpoint indicators (hamburger menu, etc.)
> System Message column truncation suggests some responsive consideration
> Critical gap: likely not usable at 375px without significant layout changes
### prompts — a11y: 2/5
> No visible focus indicators on interactive elements
> Status column uses color (draft/active) without additional visual differentiation
> Text contrast on dark background appears adequate for most elements
> Navigation icons should be supplemented with accessible labels (unclear if present)
> Edit links lack underline or button styling that aids discovery
> Truncated System Message text ('You are a support agent...') may not be keyboard accessible
### prompts — density: 2/5
> Table rows are very compact with minimal vertical padding
> Long Entity IDs (UUIDs) consume excessive horizontal space
> System Message column truncates text making full content inaccessible
> Large amount of empty space below the 2-row table suggests poor use of viewport
> Sidebar navigation has appropriate spacing
> Overall page feels sparse with only 2 table entries visible and no pagination or additional content
### prompts — responsive: 2/5
> Fixed sidebar layout may not adapt well to mobile viewport (375px)
> Wide table with 5 columns will likely require horizontal scroll on mobile
> Entity ID column contains long UUIDs that will force table width
> No visible responsive adaptation patterns (hamburger menu, collapsible sidebar)
> Desktop layout appears appropriate for 1280px viewport

## Fix Backlog (prioritized)
| Priority | Screen | Dimension | Action |
|----------|--------|-----------|--------|
| P1 | all-screens (flash) | consistency | flash_tone_class/1 (lib/scoria_web/ui.ex) renders flash banners with raw palette |
| P1 | connectors | density | Empty states consume significant vertical space with minimal information |
| P1 | eval_specs | a11y | Cannot verify focus-visible states from static screenshot |
| P1 | eval_specs | density | Large amount of empty space below the 2-row table - viewport underutilized |
| P1 | eval_specs | responsive | Fixed sidebar navigation would likely cause issues at 375px mobile width |
| P1 | prompt_release | a11y | Dark background with light text meets contrast requirements |
| P1 | prompt_release | density | Table has only 2 rows visible with significant empty space below |
| P1 | prompt_release | responsive | Layout appears optimized for desktop viewport (1280px+) |
| P1 | prompts | a11y | No visible focus indicators on interactive elements |
| P1 | prompts | density | Table rows are very compact with minimal vertical padding |
| P1 | prompts | responsive | Fixed sidebar layout may not adapt well to mobile viewport (375px) |
