# ADR-008 — Swedish eID as a port, no personnummer

Status: accepted
Date: 2026-09-14

## Decision

BankID is an `AuthMethod` on the same auth port as passkeys and GitHub. The in-memory studio fakes a successful ceremony (recovery-phrase wrap, no password) so tests and CI never hold a relying-party certificate. That fake is as fake as in-memory GitHub.

Cloud BankID is fail-closed configuration, not a costume:

- Both `BANKID_ISSUER` and `BANKID_CLIENT_ID`, or neither.
- Half-set throws at bootstrap, same pattern as `SUPABASE_*`.
- Unset → `AuthUnavailableFailure`: “BankID is not configured on this deployment.”
- Both set → still no live Signicat/Criipto ceremony in this build. Honest copy: the issuer is set, the ceremony is not wired.
- No silent password fallback.

Swedish UI leads with BankID, then passkey. English UI leads with passkey, then BankID. Same methods, market-aware order.

## Data minimization

If a future OIDC assertion contains `ssn`, `personalNumber`, `personal_number`, or `swedishPersonalIdentityNumber`, `sanitizeEidClaims` drops it before persist. We keep opaque `sub` and email if present. There is no personnummer field in the domain, Postgres, or the Art. 20 export.

## Rejected

Storing a Swedish personal identity number “just in case”. Shipping a live BankID certificate in GitHub Actions. Claiming DIGG approval. Building Freja eID in this cycle — it is named as future, not implemented.
