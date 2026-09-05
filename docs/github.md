# Penumbra development Kanban (GitHub)

GitHub Issues and a GitHub Project are the process board for this interview project. They are not a feature inside the studio.

- Repo: https://github.com/sebbeflebbe/penumbra
- Board: https://github.com/users/sebbeflebbe/projects/2

Issues:

- https://github.com/sebbeflebbe/penumbra/issues/1 Guiding documents (Done)
- https://github.com/sebbeflebbe/penumbra/issues/2 Canvas echo ritual (Done)
- https://github.com/sebbeflebbe/penumbra/issues/3 Cloud: wire Supabase (Done)
- https://github.com/sebbeflebbe/penumbra/issues/4 A11y: themes + EAA copy (Done)
- https://github.com/sebbeflebbe/penumbra/issues/5 Process: GitHub Project instead of Jira (Done)
- https://github.com/sebbeflebbe/penumbra/issues/6 Edit and delete human slips (Done)
- https://github.com/sebbeflebbe/penumbra/issues/7 Drag-move slips + acknowledge recovery phrase (Done)
- https://github.com/sebbeflebbe/penumbra/issues/8 Board rename, delete, Art. 18 restrict (Done)
- https://github.com/sebbeflebbe/penumbra/issues/9 Persist remote-echo consent + erase re-auth (Done)
- https://github.com/sebbeflebbe/penumbra/issues/10 Cloud WebAuthn passkeys (Done)
- https://github.com/sebbeflebbe/penumbra/issues/11 Unavailable-path tests + honest copy (Done)
- https://github.com/sebbeflebbe/penumbra/issues/12 A11y lockstep after new controls (Done)
- https://github.com/sebbeflebbe/penumbra/issues/13 Env/imprint/ADR/story/OSV hygiene (Done)
- https://github.com/sebbeflebbe/penumbra/issues/15 Phrase unlock when the device wrap is gone
- https://github.com/sebbeflebbe/penumbra/issues/16 Withdraw remote-echo consent (Art. 7(3))
- https://github.com/sebbeflebbe/penumbra/issues/17 Register a passkey from an existing session
- https://github.com/sebbeflebbe/penumbra/issues/18 Art. 16 display name + Art. 20 downloadable export
- https://github.com/sebbeflebbe/penumbra/issues/19 Split canvas_page.dart with no behaviour change
- https://github.com/sebbeflebbe/penumbra/issues/20 Index / Move a11y deepening
- https://github.com/sebbeflebbe/penumbra/issues/21 Test holes for already-shipped UI
- https://github.com/sebbeflebbe/penumbra/issues/22 Story / ADR / origin runbook / 1.2.0 honesty

Four-week spec (Weeks 5–8): [roadmap.md](roadmap.md). Versioning and GitHub Flow: [versioning.md](versioning.md).

## Ritual

1. Before coding a slice: create or pick the issue (`gh issue create` / `gh issue list`); add the `status:in-progress` label (the Action moves the Project card to **In Progress**).
2. When the slice lands: comment with what changed; close the issue (the Action moves the card to **Done**). PRs should say `Fixes #N` so opening the PR also marks **In Progress**.
3. Do not let the board rot.

## Labels

- `status:in-progress` — this chat (or a PR) is working the slice.
- `week-1` … `week-4` — first deepening (shipped).
- `week-5` … `week-8` — current enhancement slices.

Opened issues land in **Todo**. Closed issues land in **Done**. `.github/workflows/project.yml` keeps the Project Status field in sync when `PROJECTS_TOKEN` and `PENUMBRA_PROJECT_NUMBER` are set.

## This chat

Use the GitHub CLI, not Atlassian:

```bash
gh issue list
gh issue create --title "..." --body "..."
gh issue comment N --body "..."
gh issue edit N --add-label status:in-progress
gh issue close N
```
