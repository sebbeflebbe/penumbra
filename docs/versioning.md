# Versioning and GitHub Flow

Penumbra follows [SemVer 2.0](https://semver.org/) and **GitHub Flow**: short-lived branches, pull request into `main`, no `develop` branch and no long-lived `release/*` trains.

The product version lives only in `pubspec.yaml` as Flutter expects: `MAJOR.MINOR.PATCH+BUILD`.

## When to bump

- **MAJOR** — breaking privacy, auth, or storage contract (encryption, fail-closed config, session / DEK wrap, RLS meaning).
- **MINOR** — user-visible capability (new ritual, rights UI, cloud passkeys).
- **PATCH** — fix, copy, accessibility, CI, or docs that do not add capability.
- **+BUILD** — increment on every versioned PR. Never reuse a build number.

Do not bump Forui or Flutter as a side effect of a product bump (ADR-001: Forui 0.22.2, CI Flutter 3.44.1).

## Branch naming

```
{bump}/v{MAJOR}.{MINOR}.{PATCH}-{slug}
```

`{bump}` is `major`, `minor`, or `patch` and **must match** the pubspec bump on that branch. `{slug}` is lowercase kebab-case and names one concern.

Examples:

- `minor/v1.1.0-ritual-deepening`
- `patch/v1.1.1-passkey-copy`

Same name locally and on `origin`. PR title starts with `vX.Y.Z:`.

## Agent ritual

1. Never commit on `main`. Create the versioned branch from up-to-date `main` **before** editing.
2. First change on the branch includes the `pubspec.yaml` bump.
3. Commit, then `git push -u origin HEAD`.
4. Open a PR to `main` (`gh pr create --base main`). Use `Fixes #N` only when an issue is still open.
5. Do not merge until CI is green: **analyze**, **test**, **build-web**, **supply-chain**. Deploy runs on `main` only.

## CI gates

Pull requests and `main` run four required jobs (see `.github/workflows/ci.yml`):

- **analyze** — `dart analyze --fatal-warnings`
- **test** — `flutter test --coverage` (in-memory studio; no Supabase secrets)
- **build-web** — `flutter build web --release` (proves the interview artifact ships)
- **supply-chain** — CycloneDX SBOM + OSV on `pubspec.lock`

**deploy** is not a PR gate. It runs on `main` only when `CLOUDFLARE_PROJECT_NAME` is set.

Repo settings (manual): require those four checks on `main`; disallow direct pushes if branch protection is available.

## Out of scope here

GitFlow release trains. Live Supabase or WebAuthn in CI. Auto-tagging (`vX.Y.Z` after merge is optional later).
