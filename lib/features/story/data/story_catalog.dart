class StoryChapter {
  const StoryChapter({
    required this.id,
    required this.title,
    required this.control,
    required this.body,
  });

  final String id;
  final String title;
  final String control;
  final String body;
}

abstract final class StoryCatalog {
  static const chapters = [
    StoryChapter(
      id: '00',
      title: 'The brief',
      control: 'Product choice',
      body: '''
The assignment asked for technical excellence, accessibility, TDD, GDPR, multi-method login, Flutter web, and a parallel development story — on a free host.

A generic dashboard would have shown CRUD. A canvas that is usually inaccessible and usually plaintext is a harder problem. Penumbra is a spatial notebook: private by default, visible only to you, accessible by design. The making-of is a product route, not a leftover README.
''',
    ),
    StoryChapter(
      id: '01',
      title: 'Stack',
      control: 'ADR-001',
      body: '''
Flutter 3.44 web, Forui 0.22 (the last line that matches this SDK), Riverpod, go_router, cryptography.

Supabase in Frankfurt is the production backend; an in-memory studio with the same contracts is the default so tests and reviewers do not need secrets. Cloudflare Pages hosts the static build.

We did not pull Google Fonts at runtime. Forui already ships Inter. Display type is Fraunces, bundled under OFL. A font CDN would have been a processor, a CSP hole, and a transfer.
''',
    ),
    StoryChapter(
      id: '02',
      title: 'Auth',
      control: 'eIDAS 2 / GDPR Art. 32',
      body: '''
Five methods: passkeys, Google, GitHub, magic link, password. Passkeys are first in the layout because they are phishing-resistant. On the cloud path they are real WebAuthn against Supabase Auth; the in-memory studio still fakes a passkey session so reviewers need no authenticator. Passwords are last and must be twelve characters. OAuth providers are independent controllers for their own identity data.

OAuth users do not have a password to derive a wrapping key. They get a twelve-word recovery phrase once. That tradeoff is the honest part of the encryption story. WebAuthn PRF wrapping is still future work.
''',
    ),
    StoryChapter(
      id: '03',
      title: 'Canvas and crypto',
      control: 'GDPR Art. 32 / NIS2 crypto policy',
      body: '''
Cards are widgets, not paint, so they exist in the semantics tree. A list beside the canvas is the screen-reader order. Arrow keys or a named Move handle reposition the focused card. Human slips can be edited and deleted; deleting a parent also removes its echo.

Payloads are AES-256-GCM. Tests assert the stored form does not contain plaintext, and that another user cannot read a board (the RLS contract). Restricted boards refuse writes, including delete (Art. 18).
''',
    ),
    StoryChapter(
      id: '04',
      title: 'European operations',
      control: 'GDPR, CRA alignment, EN 301 549',
      body: '''
We bind to GDPR if EU personal data is processed. We align to the CRA and NIS2 catalogs without claiming we are a designated entity or a CE-marked manufacturer. The accessibility bar is EN 301 549 (the EAA’s technical standard). The Act applies from 28 June 2025; a personal notebook is likely outside its sectors. We still design to that bar and do not claim full EAA conformance.

US-parent residual risk is written down. That sentence is more adult than a fake “100% EU” badge. Optional Gemini echoes are the same honesty: a processor, a transfer, a consent — or a local voice and no Google at all.
''',
    ),
    StoryChapter(
      id: '05',
      title: 'TDD and CI',
      control: 'CRA SBOM / supply chain',
      body: '''
Domain tests were written before the UI: crypto round-trips, recovery checksums, RLS isolation, export/erasure, Art. 18 restriction.

CI runs analyzer, tests, an OSV scan of pubspec.lock, and a CycloneDX SBOM. The SBOM is an artifact, not a marketing PDF.
''',
    ),
    StoryChapter(
      id: '06',
      title: 'Name, mark, and motion',
      control: 'WCAG 2.2.3 / EN 301 549 7.1 / ADR-006',
      body: '''
Lumen was too bright a word for a product that lives in the half-light of private notes. Penumbra is the partial shadow of an eclipse — the in-between of light and dark. The mark is that eclipse: a dark disk eating a pale one, a copper rim at the uncertain edge.

Display type is Fraunces, bundled. Motion is a 12px rise and a fade, and it is a no-op when the user asks for reduced motion. That is WCAG 2.2.3, not decoration.
''',
    ),
    StoryChapter(
      id: '07',
      title: 'Dialogue with the half-light',
      control: 'GDPR Art. 6(1)(a) / ADR-007',
      body: '''
The board was still a file. We replaced that with one ritual: every human slip may summon one nearby echo. The original words stay. The Index is that conversation.

Gemini 3.5 Flash-Lite is the smallest current Flash-Lite. It sees only the summoned slip, after an explicit consent. Without a key, a local Penumbra voice still rephrases — the same secret-free story as the in-memory studio. A silent rewrite would have been easier, and a lie.
''',
    ),
    StoryChapter(
      id: '08',
      title: 'Cloud, themes, and the board we work on',
      control: 'Supabase / EN 301 549',
      body: '''
The in-memory studio is still how tests and reviewers enter. When both Supabase dart-defines are set, the same contracts hit Frankfurt: Auth, RLS, ciphertext in Postgres. Half a config is a closed door.

The European Accessibility Act applies from 28 June 2025. A personal notebook is likely outside its sectors. We still treat EN 301 549 as the bar — named themes that persist, high-contrast that is actually black and white, a canvas you can read without the spatial view.

Development lives on GitHub Issues and a Project Kanban. The agent moves issues as this chat proceeds. That board is not a feature inside the studio.
''',
    ),
    StoryChapter(
      id: '09',
      title: 'The four-week deepening',
      control: 'Roadmap / GitHub Issues',
      body: '''
The studio already had a ritual. Four weeks deepened it rather than adding chrome.

Place is reversible: edit, delete (with cascade), and a Move handle that yields the sheet pan while dragging. Recovery phrases can be acknowledged. Boards expose rename, delete, and Art. 18 restrict in the list the legal copy already promised. Remote echoes persist Art. 6(1)(a) consent. Erasure asks for the password the studio always required.

Cloud passkeys call Supabase Auth WebAuthn plus the browser ceremony. The in-memory studio still fakes passkey, Google, GitHub, and magic link so CI never needs secrets. The DEK wrap for passkeys remains the twelve-word phrase; WebAuthn PRF is still future work.

The plan is `docs/roadmap.md`. Issues #6–#13 are the board. This chapter is the retrospective, not a promise of work still undone.
''',
    ),
  ];
}
