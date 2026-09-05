# Penumbra — agent guide

Read this first. Product is small; craft is the interview artifact.

## Principles

- **Private by default.** Card bodies are AES-256-GCM in the browser. Do not send the board, titles, or other slips to a model. Echoes send one slip, after Art. 6(1)(a) consent, or stay local.
- **Cloud is real.** When `SUPABASE_URL` and `SUPABASE_ANON_KEY` are both set, Auth, boards, encrypted nodes, and privacy rights hit Supabase (Frankfurt, RLS). If only one is set, fail closed. If neither is set, use the in-memory studio. Tests and CI never need secrets.
- **EAA / EN 301 549.** Keyboard, named controls, contrast, reduced motion, 48px-class targets. A personal notebook may sit outside EAA sectoral scope; still treat EN 301 549 as the bar. Do not claim full EAA conformance.
- **Themes are first-class.** System / light / dark / high-contrast stay visually distinct and persist (necessary storage only). High-contrast is true black/white.
- **UX depth over chrome.** One ritual done well: Place, nearby echo, Index as conversation. No extra dashboards. No Kanban inside the studio.
- **TDD.** Domain tests before UI. Domain has no Flutter and no Supabase.
- **Passkeys first.** Then Google, GitHub, magic link, password (12+). Honesty over badges: no fake CE, NIS2 entity, or ISO 27001.
- **Making-of is a route.** ADRs and `/making-of` stay in lockstep with the code.

## GitHub Issues + Project (development board)

GitHub is the process board, not a product feature. See `docs/github.md`. Repo: https://github.com/sebbeflebbe/penumbra

1. Before coding a slice: create or pick the issue; add `status:in-progress` (Project: **In Progress**).
2. When the slice lands: comment with what changed; close the issue (Project: **Done**). PRs use `Fixes #N`.
3. Do not let the board rot.

Use `gh issue` / `gh project`, not Atlassian.

## Stack

Flutter web, Forui 0.22.2, Riverpod, go_router. In-memory studio mirrors Supabase contracts. No runtime Google Fonts.
