# ADR-001 — Stack

Status: accepted
Date: 2026-08-31
Amended: 2026-09-05

Use Flutter web + Forui 0.22.2 + Riverpod + an in-memory studio that mirrors the live Supabase Frankfurt backend, hosted on Cloudflare Pages.

The in-memory studio is the default for tests and reviewers. The same contracts hit Supabase when both `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set. CI stays on Flutter 3.44.1.

Rejected Firebase as the primary GDPR story (less portable, weaker EU narrative). Rejected latest Forui 0.26 because it requires Flutter 3.47.
