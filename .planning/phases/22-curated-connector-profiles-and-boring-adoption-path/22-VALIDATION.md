# Phase 22 Validation: Curated Connector Profiles and Boring Adoption Path

## Phase Goal
Productize Scoria's remote connector adoption path with a thin curated profile layer and a boring default install/verification experience for normal Phoenix apps, ensuring the operator surface reflects the durable runtime truth.

---

## Requirement Mapping & Verification

### DX-01. Scoria ships a small curated connector/profile layer for common remote-tool adoption paths without becoming a connector marketplace.
* **Covered By Plans:** 22-01
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test test/scoria/connectors/profiles_test.exs` - asserts `Profiles.build_attrs/2` correctly normalizes `:generic` and `:github` profiles into valid Ecto attributes with safe defaults (stateless-first, `streamable_http`).
  * **Automated:** `mix test test/scoria/connectors/profiles_test.exs` - asserts unknown profile atoms raise `ArgumentError`, enforcing a controlled curated set.

### DX-02. The default install and verification path for remote connectors stays boring for an ordinary Phoenix app integration.
* **Covered By Plans:** 22-01, 22-02
* **Concrete Verification Steps (Nyquist Compliant):**
  * **Automated:** `mix test.adoption` - asserts the connector-specific executable proof (registration, sync-stubbing, and grant persistence) runs successfully as part of the default adoption lane.
  * **Automated:** `mix test test/scoria/connectors/profiles_test.exs` - asserts that after registration via a profile, the connector appears in the operator surface truth (e.g., via `Scoria.Connectors.list_connector_fleet/1`).
  * **Automated:** `grep -i "Remote Connector" docs/operator_verification.md` - asserts the human walkthrough exists and aligns with the executable profile-first registration path.

---

## Nyquist Compliance Checklist
- [ ] **DX-01:** Curated profiles normalize to durable Ecto attributes without bypassing the `Scoria.register_connector/1` boundary.
- [ ] **DX-02:** Remote connector verification is integrated into `mix test.adoption` and uses offline-first stubbing.
- [ ] **Operator Truth:** Executable proofs assert that the operator surface (fleet listing) correctly reflects the newly registered connector.
