# Penumbra development Kanban (GitHub)

GitHub Issues and a GitHub Project are the process board for this interview project. They are not a feature inside the studio.

Repo: https://github.com/sebbeflebbe/penumbra

## Ritual

1. Before coding a slice: create or pick the issue (`gh issue create` / `gh issue list`); add the `status:in-progress` label (the Action moves the Project card to **In Progress**).
2. When the slice lands: comment with what changed; close the issue (the Action moves the card to **Done**). PRs should say `Fixes #N` so opening the PR also marks **In Progress**.
3. Do not let the board rot.

## Labels

- `status:in-progress` — this chat (or a PR) is working the slice.

Opened issues land in **To do**. Closed issues land in **Done**. `.github/workflows/project.yml` keeps the Project Status field in sync when `PROJECTS_TOKEN` and `PENUMBRA_PROJECT_NUMBER` are set.

## This chat

Use the GitHub CLI, not Atlassian:

```bash
gh issue list
gh issue create --title "..." --body "..."
gh issue comment N --body "..."
gh issue edit N --add-label status:in-progress
gh issue close N
```
