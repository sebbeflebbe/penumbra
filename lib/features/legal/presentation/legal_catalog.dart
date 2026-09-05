class LegalDocument {
  const LegalDocument({
    required this.title,
    required this.slug,
    required this.body,
  });

  final String title;
  final String slug;
  final String body;
}

abstract final class LegalCatalog {
  static const documents = [privacy, terms, imprint, accessibility, security];

  static const privacy = LegalDocument(
    title: 'Privacy policy',
    slug: 'privacy',
    body: '''
Penumbra is a personal visual thinking studio. The developer operating a given deployment is the controller under the GDPR.

We process account identifiers, board titles, encrypted card payloads, consent records, and short-lived security events. Board bodies are encrypted in the browser with AES-256-GCM. The hosting database is intended to sit in the EU (eu-central-1 Frankfurt) when you connect a Supabase project.

Lawful basis for the studio itself is contract (Art. 6(1)(b)). Summoning an echo is optional and separate: that one slip’s text may be sent to Google LLC (Gemini 3.5 Flash-Lite) under your consent (Art. 6(1)(a)). The rest of the board is not sent. Without a key, a local voice answers and nothing leaves the browser.

We do not use marketing or analytics cookies. The only device storage is strictly necessary: session, theme, and key-wrapping material.

You may access and port your data as JSON, restrict a board (Art. 18), and erase your account after re-authentication (Art. 17). We aim to complete rights requests within 30 days.

Processors, when a remote backend is configured: Supabase (Auth, Postgres, Storage) and Cloudflare Pages (static hosting). Google and GitHub act as independent controllers for OAuth identity. If you summon an echo with a configured Gemini key, Google LLC is also a processor for that one slip.

Transfers: even with an EU database, Supabase Inc. and Cloudflare, Inc. are US companies. Gemini is a US residual risk as well. Client-side encryption of card bodies is the primary mitigation for stored notes; an echo in flight is plaintext to Google. We do not claim that this residual risk is zero.

This policy is a working text for an interview deployment. Replace the controller identity before inviting real EU users.
''',
  );

  static const terms = LegalDocument(
    title: 'Terms of use',
    slug: 'terms',
    body: '''
Penumbra is provided as an interview and research studio. It is free of charge. The free hosting and database tiers may pause after inactivity; we disclose that availability risk instead of hiding it.

You must be 16 or older. Do not upload unlawful content. Boards are private in v1; there is no public sharing surface.

Passkeys are preferred. Recovery phrases for OAuth accounts are shown once. If you lose the phrase and the device, we cannot decrypt your cards.

These terms are not a consumer contract for a placed-on-market product under the Cyber Resilience Act. See the security page for what we align to without claiming CE marking.
''',
  );

  static const imprint = LegalDocument(
    title: 'Imprint',
    slug: 'imprint',
    body: '''
Controller (placeholder): set PENUMBRA_CONTROLLER_NAME and PENUMBRA_CONTROLLER_EMAIL when you deploy.

This page exists so a German or Austrian reviewer can find an Impressum-shaped identity. Fill it before public EU use.

No commercial register. No VAT. Personal interview project.
''',
  );

  static const accessibility = LegalDocument(
    title: 'Accessibility statement',
    slug: 'accessibility',
    body: '''
The European Accessibility Act applies from 28 June 2025. We design Penumbra against EN 301 549 v3.2.1 (web chapter = WCAG 2.1 Level AA). A personal notebook is likely outside the Act’s sectoral scope. We still treat the standard as the bar and do not claim full EAA conformance.

Implemented: skip-to-content focuses a main landmark, visible focus rings via Forui, named and persisted appearance (System, Light, Dark, High contrast), true black/white high-contrast, reduced-motion no-ops (WCAG 2.2.3), named canvas cards, a list alternative to the spatial canvas, named Edit / Delete / Move / Restrict / Unrestrict controls, 48px-class targets on primary actions, Flutter web semantics enabled on startup.

Known gaps: Flutter web paints to a canvas, so the accessibility tree is an opt-in overlay. InteractiveViewer is not itself a spatial map in that tree — the Index and the Move handle are the mitigation. Contrast of third-party Forui defaults is AA in high-contrast mode by construction; the zinc theme helper text is darkened relative to the paper ground but is not a formal laboratory measurement. This statement is dated 5 September 2026.

Contact: the controller email on the privacy page.
''',
  );

  static const security = LegalDocument(
    title: 'Security',
    slug: 'security',
    body: '''
Report vulnerabilities to the address in /.well-known/security.txt. Preferred languages: English, Swedish. We do not pay a bounty on this interview deployment.

Aligned practices (not certifications): GDPR Art. 32; NIS2 Art. 21 used as a control catalog; CRA Annex I secure-by-default, SBOM in CI, coordinated disclosure playbook. We do not claim NIS2 entity status, CE marking, or ISO 27001.

Passkeys are phishing-resistant and preferred. RLS (or the in-memory equivalent) is the authorisation boundary. Service-role keys never ship in the client. Gemini keys, when used, are compile-time dart-defines and are not stored with the notes.

Optional echoes are a new processor: Google LLC, one-slip payload, Art. 6(1)(a) consent, fail closed. The in-memory studio and tests never hit the network.

Flutter web Content-Security-Policy cannot be as strict as a classic HTML app because of CanvasKit/Skwasm. That gap is documented in ADR-004. Echo traffic is limited to `https://generativelanguage.googleapis.com` (ADR-007).
''',
  );
}
