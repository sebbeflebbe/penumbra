# ADR-007 — Optional Gemini echo, one slip, explicit consent

Status: accepted
Date: 2026-08-31

## Decision

A human slip may summon one nearby echo. The original words stay on the sheet. The echo is a companion, not a rewrite.

When a Gemini API key is present (`--dart-define=GEMINI_API_KEY=…`), that **one slip’s text** is sent to Google LLC (`gemini-3.5-flash-lite` at `generativelanguage.googleapis.com`). Titles, other slips, and the rest of the board are not sent. Ambient voice lives in the system instruction, not in a dump of the sky.

This is a new processor and a Chapter V transfer. First summon in a session asks for consent (GDPR Art. 6(1)(a)) in a Forui dialog — not a footnote on the privacy page. US residual risk remains, as in ADR-003.

## Fallback

Without a key — the default for tests, reviewers, and the in-memory studio — a local Penumbra voice rephrases the feeling and never leaves the browser. The product works without Google.

Timeout, 4xx, or an empty model fail closed: the human slip is untouched.

## CSP

`connect-src` allows only `https://generativelanguage.googleapis.com` in addition to self and Supabase. No Google Fonts CDN (ADR-005).

## Rejected

Silent rewrite-in-place. Sending the whole board as “context”. Auto-summon on Place. A chat thread. Pretending the transfer is not a transfer.
