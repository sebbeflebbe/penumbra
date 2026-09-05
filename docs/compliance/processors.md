# Processor register (Art. 28)

| Processor | Role | Region | DPA |
| --- | --- | --- | --- |
| Supabase | Auth, Postgres, Storage (when configured) | eu-central-1 Frankfurt | Sign in dashboard |
| Cloudflare | Static hosting / CDN | Global edge | Sign in dashboard |

Google and GitHub are **independent controllers** for OAuth identity, not processors of board content.

No other subprocessors in v1 without an ADR.
