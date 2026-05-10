# szTheory Elixir Architectural DNA
*SaaS in a Box - Unix Philosophy for Elixir Libraries*

This document captures the core architectural DNA, best practices, and lessons learned from the `szTheory` ecosystem (e.g., Sigra, Rindle, Accrue, Lockspire, Chimeway). It serves as the foundational technical compass for the **Scoria** project.

## Core Philosophy
1. **Batteries-Included but Composable:** Provide highly opinionated, ready-to-use defaults that solve the complete problem (the "happy path"), while exposing modular layers that advanced users can customize.
2. **Unix Philosophy:** Build specialized, focused libraries that do one thing exceptionally well and compose cleanly together to form a "SaaS in a box" ecosystem.
3. **Operator-First DX:** Optimize for the solo entrepreneur or small engineering team. Prioritize automation, observability, and out-of-the-box utility over theoretical flexibility. 

## Architectural & UX Patterns
1. **Embedded LiveView Dashboards:** 
   * Every library should provide a mountable Phoenix LiveView admin/operator UI. 
   * Day-0 onboarding should be visual and immediate.
   * Day-2 operations (debugging, configuration, monitoring) should be fully supported in the dashboard.
2. **Ecto-Native State:**
   * Leverage Ecto schemas and migrations for robust, durable state management. 
   * Avoid opaque in-memory state where durable records provide better auditability and operator insight.
3. **Ecosystem Integration:**
   * Design explicit hooks for cross-library synergy.
   * **Auth:** Rely on `Sigra` for admin authentication, MFA, and RBAC.
   * **Audit:** Push events to `Threadline` for comprehensive actor/intent tracing.
   * **Notifications:** Route alerts through `Chimeway` or `Mailglass`.
   * **SRE/Alerts:** Prepare telemetry hooks for `Parapet`.

## Engineering Standards
* **Idiomatic Elixir:** Strictly functional, pipeline-oriented, and OTP-aware.
* **Robust CI/CD:** Leverage GitHub actions for exhaustive testing, Dialyzer/Credo enforcement, and security audits.
* **Zero-Configuration Onboarding:** Provide simple `mix my_lib.install` tasks to generate necessary migrations, config snippets, and router mounts.