# EN 301 549 / DOS statement

See `/legal/accessibility` in the running app. Source of this statement: `lib/features/legal/presentation/legal_catalog.dart`.
Date: 2026-09-14.
Conformance: partial, targeting WCAG 2.1 AA via EN 301 549 web chapter. Sweden’s DOS 2018 (lagen om tillgänglighet till digital offentlig service) points at the same standard. The European Accessibility Act applies from 28 June 2025; we do not claim full Act or DOS conformance, and we do not claim DIGG approval. Known gaps: Flutter web semantics overlay; InteractiveViewer is not a spatial map in the accessibility tree (Index + named Move handle are the mitigation). Locale (English / Svenska) is a named, persisted control.
