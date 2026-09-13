# ADR-002 — Key wrapping

Status: accepted
Date: 2026-08-31

Password users wrap the DEK with Argon2id(password). OAuth and passkey users wrap with a 12-word BIP39-style phrase shown once. That phrase is also the re-unlock secret: it re-derives the wrap key and unwraps the stored DEK without deleting wrap material. Cloud passkeys use Supabase Auth WebAuthn (`auth.passkey`) plus the browser ceremony; the wrap is still the recovery phrase. WebAuthn PRF is the future preferred wrap for passkeys and is not assumed available.

Rejected storing a plaintext DEK server-side. Rejected pretending social login is zero-knowledge without a recovery secret.
