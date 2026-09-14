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

We do not use marketing or analytics cookies. The only device storage is strictly necessary: session, theme, locale, and key-wrapping material.

You may access and port your data as a JSON file (Art. 15 / 20), copy that export, or download it. You may rectify your display name (Art. 16), restrict a board (Art. 18), and erase your account after re-authentication (Art. 17). Echo consent (Art. 6(1)(a)) can be withdrawn from Privacy as easily as it was given (Art. 7(3)); past consent records are kept. We aim to complete rights requests within 30 days.

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
The European Accessibility Act applies from 28 June 2025. In Sweden the public-sector bar is also DOS 2018 (lagen om tillgänglighet till digital offentlig service), which points at EN 301 549. We design Penumbra against EN 301 549 v3.2.1 (web chapter = WCAG 2.1 Level AA). A personal notebook is likely outside the Act’s sectoral scope. We still treat the standard as the bar and do not claim full EAA conformance. We do not claim full DOS conformance or DIGG approval.

Implemented: skip-to-content focuses a main landmark, visible focus rings via Forui, named and persisted appearance (System, Light, Dark, High contrast), true black/white high-contrast, reduced-motion no-ops (WCAG 2.2.3), named canvas cards, a list alternative to the spatial canvas with focusable Index rows and Up/Down roving, named Edit / Delete / Move / Restrict / Unrestrict controls, 48px-class targets on primary actions, a named locale control (English / Svenska), Flutter web semantics enabled on startup.

Known gaps: Flutter web paints to a canvas, so the accessibility tree is an opt-in overlay. InteractiveViewer is not itself a spatial map in that tree — the Index and the Move handle are the mitigation. Contrast of third-party Forui defaults is AA in high-contrast mode by construction; the zinc theme helper text is darkened relative to the paper ground but is not a formal laboratory measurement. This statement is dated 14 September 2026.

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

  static const privacySv = LegalDocument(
    title: 'Integritetspolicy',
    slug: 'privacy',
    body: '''
Penumbra är en personlig visuell ateljé. Den som driver en given installation är personuppgiftsansvarig enligt GDPR.

Vi behandlar kontoidentifierare, taveltitlar, krypterade kort, samtyckesposter och kortlivade säkerhetshändelser. Korttexter krypteras i webbläsaren med AES-256-GCM. Databasen är avsedd att ligga i EU (eu-central-1 Frankfurt) när ett Supabase-projekt kopplas. Vi lagrar inte personnummer. Om en framtida e-legitimation assertion innehåller ssn eller personalNumber slängs den innan persistens.

Rättslig grund för ateljén är avtal (art. 6.1 b). Att kalla fram ett eko är valfritt: den texten kan skickas till Google LLC (Gemini 3.5 Flash-Lite) med samtycke (art. 6.1 a). Resten av tavlan skickas inte. Utan nyckel svarar en lokal röst och inget lämnar webbläsaren.

Vi använder inte marknadsförings- eller analyskakor. Endast nödvändig lagring: session, utseende, språk och nyckelinpackning.

Du kan få ut dina data som JSON (art. 15 / 20), kopiera eller ladda ner. Du kan rätta visningsnamn (art. 16), begränsa en tavla (art. 18) och radera kontot efter ny autentisering (art. 17). Ekonsamtycke kan återkallas lika enkelt som det gavs (art. 7.3). Vi siktar på 30 dagar för rättighetsärenden.

Personuppgiftsbiträden, när moln är konfigurerat: Supabase (Auth, Postgres, Storage) och Cloudflare Pages. Google och GitHub är självständiga personuppgiftsansvariga för OAuth-identitet. BankID-leverantören, när den är inkopplad, är identitetsutfärdare — inte en lagring av nationellt id hos oss.

Överföringar: även med EU-databas är Supabase Inc. och Cloudflare, Inc. amerikanska bolag. Gemini är också en amerikansk residualrisk. Klientkryptering av kort är den primära skyddsåtgärden; ett eko i luften är klartext till Google. Vi påstår inte att residualrisken är noll. Det är den IMY-formade meningen.

Den här texten är en arbetsversion för en intervjuinstallation. Byt personuppgiftsansvarig innan riktiga användare i EU bjuds in.
''',
  );

  static const accessibilitySv = LegalDocument(
    title: 'Tillgänglighetsredogörelse',
    slug: 'accessibility',
    body: '''
DOS 2018 (lagen om tillgänglighet till digital offentlig service) pekar på EN 301 549. Europeiska tillgänglighetsdirektivet (EAA) gäller från 28 juni 2025. Vi utformar Penumbra mot EN 301 549 v3.2.1 (webbkapitlet = WCAG 2.1 AA). Ett personligt anteckningsblock ligger troligen utanför direktivets sektorer. Vi behandlar ändå standarden som ribban och hävdar inte full EAA- eller DOS-överensstämmelse, och inte DIGG-godkännande.

Genomfört: hoppa till innehållet, synlig fokusring via Forui, namngivet och sparat utseende (System, Ljust, Mörkt, Hög kontrast), äkta svart/vitt högkontrast, reducerad rörelse som no-op (WCAG 2.2.3), namngivna kort, Index med fokus och Upp/Ner, namngiven Flytta, 48 px-klass på primära åtgärder, namngivet språkval (English / Svenska), Flutter-webbsemantik vid start.

Kända luckor: Flutter web ritar på en canvas, så tillgänglighetsträdet är ett tillval. InteractiveViewer är inte en rumslig karta i det trädet — Index och Flytta är åtgärden. Den här redogörelsen är daterad 14 september 2026.

Kontakt: e-postadressen på integritetssidan.
''',
  );

  static LegalDocument forSlug(String slug, {required bool swedish}) {
    final english = documents.firstWhere(
      (d) => d.slug == slug,
      orElse: () => privacy,
    );
    if (!swedish) return english;
    return switch (slug) {
      'privacy' => privacySv,
      'accessibility' => accessibilitySv,
      _ => english,
    };
  }
}
