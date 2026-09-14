# Operator notes

Short checklist for a live Pages + Frankfurt deployment. Do not invent a controller email here; set `PENUMBRA_CONTROLLER_NAME` and `PENUMBRA_CONTROLLER_EMAIL` in dart-defines before inviting real EU users.

## Origin and passkeys

`PENUMBRA_ORIGIN` must equal the Cloudflare Pages HTTPS origin (scheme + host, no trailing path). Locally that is `http://localhost` (or the port you actually serve). If the origin and the Auth relying party disagree, WebAuthn register and sign-in fail.

Enable **Passkeys** on the Frankfurt (eu-central-1) Supabase Auth settings. Cloud register from Privacy is a real browser ceremony; CI never has those secrets.

## Deploy

Set `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID`, and `CLOUDFLARE_PROJECT_NAME` so the `deploy` job on `main` can publish `build/web`. Leave `CLOUDFLARE_PROJECT_NAME` empty if Pages is not configured — do not claim a live host in that case.

Apply `supabase/migrations/` on the Frankfurt project. Set **both** `SUPABASE_URL` and `SUPABASE_ANON_KEY`, or neither.

BankID follows the same rule: both `BANKID_ISSUER` and `BANKID_CLIENT_ID`, or neither. This build still does not run a live BankID ceremony when they are set. Unset is honest unavailable copy. Do not put a relying-party certificate in CI.

## Branch protection

Optional GitHub setting on `main`: require the four PR checks **analyze**, **test**, **build-web**, and **supply-chain**. Direct pushes to `main` should stay off. See `docs/versioning.md`.
