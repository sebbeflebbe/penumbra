# ADR-002 — Key wrapping

Status: accepted
Date: 2026-08-31

Password users wrap the DEK with Argon2id(password). OAuth and passkey users wrap with a 12-word BIP39-style phrase shown once. WebAuthn PRF is the future preferred wrap for passkeys and is not assumed available.

Rejected storing a plaintext DEK server-side. Rejected pretending social login is zero-knowledge without a recovery secret.
