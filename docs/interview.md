# Interview talk — Penumbra (consultancy)

Speaker sheet for a 10–15 minute **Swedish consultant-firm** room. Technology first; the notebook is the vessel. Expand any section; skip one if time is short. The in-app story is `/making-of`. If this page and the making-of disagree, the making-of wins.

Do not claim CE marking, NIS2 entity status, ISO 27001, DIGG approval, or full EAA / DOS conformance. Do not pretend in-memory BankID, Google, GitHub, magic link, or passkey are live ceremonies. Do not invent a controller email. Never persist a personnummer.

## 1. Opener (~30s)

- This is a delivery case, not a startup pitch. I used a small product so the architecture is visible in one sitting.
- The question was: how would I ship a Swedish, regulated, accessible app — fail-closed integrations, eID without hoarding identity numbers, EN 301 549 / DOS language, tests that do not need cloud secrets.
- Flutter web, Frankfurt when configured, in-memory studio when not. Private notes stay the demo surface.

## 2. Architecture and fail-closed config (~2 min)

- **Hook.** A half-wired integration is worse than none. Consultants get burned on “it works on my machine” secrets.
- **What I built.** Domain contracts have no Flutter and no Supabase. `InMemoryStudio` and `SupabaseStudio` implement the same ports. Both `SUPABASE_*` or neither. Both BankID dart-defines or neither. Tests and CI never need certificates.
- **Point at.** ADR-001, `PenumbraConfig`, `resolveStudioMode` / `resolveEidMode`.
- **Tradeoff.** Firebase rejected (weaker EU story). Forui pinned to 0.22.2 so CI stays on Flutter 3.44. I would rather be a version behind than a SDK lottery.

## 3. Crypto (~2 min)

- **Hook.** “Encrypted at rest” is a slide. I wanted a sentence I can finish without lying.
- **What I built.** AES-256-GCM in the browser. Password wraps the DEK with Argon2id. BankID / OAuth / passkey wrap with a 12-word phrase — also the re-unlock secret when the device wrap is gone.
- **Point at.** ADR-002, locked studio.
- **Tradeoff.** WebAuthn PRF is the future preferred wrap. It is not assumed. No fake PRF.

## 4. Swedish eID as a port (~2 min)

- **Hook.** BankID is table stakes in this market. Shipping a personnummer field is how you fail a security review.
- **What I built.** `AuthMethod.bankId` on the same auth port as GitHub. In-memory: fake ceremony, recovery-phrase wrap, no password. Cloud: fail closed if only one of issuer / client id is set; unset → honest unavailable copy. Swedish UI leads with BankID; English leads with passkey. Same methods, market-aware order.
- **Point at.** ADR-008, sign-in, `sanitizeEidClaims` (drops `ssn` / `personalNumber`).
- **Tradeoff.** In-memory BankID is as fake as in-memory GitHub so CI never holds a relying-party cert. Freja is named as future, not built. Opaque `sub` only — no national ID in Postgres.

## 5. Accessibility as delivery risk (~2 min)

- **Hook.** In Sweden this is DOS 2018 plus EAA / EN 301 549 — a delivery risk, not a theme picker.
- **What I built.** Named cards, focusable Index with Up/Down, named Move, true black/white high-contrast, reduced motion as a no-op. Locale is a named control, persisted as necessary storage only.
- **Point at.** Index, `/legal/accessibility` (sv + en).
- **Tradeoff.** InteractiveViewer is not a spatial map. Index + Move are the mitigation. Partial claim only. Not DIGG-godkänd.

## 6. GDPR rights as UI (~1–2 min)

- **Hook.** A policy PDF the product cannot perform is a liability in an IMY conversation.
- **What I built.** Export as a file (Art. 20), display name (Art. 16), restrict (Art. 18), erase after re-auth (Art. 17), withdraw echo consent (Art. 7(3)). Privacy lists **security events** — time, type, coarse detail; no bodies, no phrases, no personnummer.
- **Point at.** Privacy page, Art. 20 JSON (includes events).
- **Tradeoff.** US-parent residual risk for Cloudflare and Supabase Inc. is written down in Swedish and English. Encryption mitigates stored notes; an echo in flight is plaintext to Google.

## 7. How a team ships (~2 min)

- **Hook.** Process should look like a delivery organisation, not a pretty README.
- **What I built.** Domain tests first. SemVer branches; never commit on `main`; merge when analyze, test, build-web, and supply-chain (CycloneDX + OSV) are green. GitHub Issues + Project is the Kanban — not a feature inside the studio.
- **Point at.** `docs/versioning.md`, CI, making-of chapter 11.
- **Tradeoff.** Honesty over badges. GitHub instead of Jira so the product does not grow a second product.

## 8. Demo path (~2 min on screen)

In-memory is enough. Default English so finders stay stable; switch language in chrome.

1. **Svenska** — BankID leads on Sign in. Continue with BankID (fake). Save the phrase if shown.
2. Open the seeded board — Index, Move, Place.
3. **Privacy** — security events after sign-in; Export / Download JSON. Confirm the JSON has no personal identity number.
4. Optional: `/making-of` chapter 11. Optional: English again — passkey leads.

Cloud BankID stays operator-only. Demo studio already has a passkey; use password sign-up to show **Add a passkey**.

## Likely questions

**Why fake BankID in CI?** A relying-party certificate in GitHub Actions is a secret and a lie about production. The port, fail-closed config, and unavailable copy are what I can test. Same pattern as Gemini and passkeys.

**Do you store personnummer?** No. If a future OIDC assertion contains `ssn` or `personalNumber`, it is dropped before persist. Opaque subject + optional email only.

**Why Frankfurt?** EU data residency for the database. US-parent residual risk is still disclosed. Client-side encryption is the mitigation, not a “100% EU” badge.

**Why Index instead of a canvas map?** InteractiveViewer does not expose x/y in the accessibility tree. Faking a map is a DOS/EN 301 549 claim I cannot keep.

**What would you do next on a kommun contract?** Wire a real BankID broker (Criipto/Signicat) behind the existing dart-defines; Freja as a second eID; full Swedish legal texts reviewed by counsel; PRF when authenticators make it safe. Not more chrome.
