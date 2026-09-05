# Cryptography policy

In transit: TLS 1.3 via Cloudflare and Supabase.

At rest (nodes): AES-256-GCM, 256-bit DEK, unique nonce per payload.

Wrapping: Argon2id (production memory 19456 KiB, 2 iterations) or 12-word recovery phrase.

Keys never logged. Algorithm review date: 2026-08-31.
