# Penumbra

A privacy-first visual thinking studio. Private by default. Visible only to you. Accessible by design.

This is a Flutter **web** app: an interview piece that treats encryption, EN 301 549 / EAA-minded accessibility, multi-method authentication, a real Supabase backend when configured, and European legal operations as product features. The making-of is a route (`/making-of`). Agent principles live in `AGENTS.md`. Development is tracked on GitHub Issues and a Project (`docs/github.md`), not inside the studio.

## Run locally

```bash
flutter pub get
flutter test
flutter run -d chrome
```

No Supabase project is required for the demo or for CI. `Enter the studio` creates an in-memory session with seeded cards. The same in-memory studio is what the tests exercise.

Set **both** `SUPABASE_URL` and `SUPABASE_ANON_KEY`, or neither. A half-set config fails closed. To point at a real EU backend:

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY \
  --dart-define=PENUMBRA_CONTROLLER_NAME='Your name' \
  --dart-define=PENUMBRA_CONTROLLER_EMAIL='you@example.com' \
  --dart-define=PENUMBRA_ORIGIN=https://YOUR.pages.dev
```

Create the project in **eu-central-1 (Frankfurt)**. Apply `supabase/migrations/`. Fill imprint fields before any real EU users. Sign the vendor DPAs in the Cloudflare and Supabase consoles.

## Auth

Passkeys, Google, GitHub, magic link, and password (12+ characters). Passkeys are first in the layout. On a configured Supabase project they use WebAuthn (`auth.passkey`); enable Passkeys in the Frankfurt Auth settings and set `PENUMBRA_ORIGIN` to the exact HTTPS origin (or localhost) or the ceremony will fail. The in-memory demo still fakes a passkey session. OAuth users receive a 12-word recovery phrase once — that phrase wraps the data-encryption key when there is no password. WebAuthn PRF wrapping is not assumed.

## GDPR and cybersecurity (honest scope)

Binds if EU personal data is processed: GDPR, ePrivacy (necessary storage only).

Aligned, not certified: CRA secure-by-default + SBOM + coordinated disclosure; NIS2 Art. 21 as a control catalog; EN 301 549 as the accessibility bar (EAA from 28 June 2025; we do not claim full Act conformance). We do **not** claim CE marking, NIS2 entity status, or ISO 27001.

## Deploy (free)

GitHub Actions builds `web`, scans `pubspec.lock` with OSV, writes a CycloneDX SBOM, and can deploy `build/web` to Cloudflare Pages. Set `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `CLOUDFLARE_PROJECT_NAME` to enable the deploy job.
