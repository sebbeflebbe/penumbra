# ADR-005 — Bundled Inter instead of Google Fonts

Status: accepted
Date: 2026-08-31

Forui ships Inter under the OFL. Display type is Fraunces, also OFL, bundled at `assets/fonts/`. Runtime Google Fonts would add a processor, a transfer, and a CSP `style-src`/`font-src` exception. We keep both typefaces local. See ADR-006.
