# ADR-006 — Identity, bundled serif, reduced motion

Status: accepted
Date: 2026-08-31

## Name

The product is **Penumbra**: the partial shadow of an eclipse, the in-between of light and dark. It keeps the Latin register of the earlier working name without sounding like a lamp.

## Mark

A partial eclipse on warm paper. No letterform, no Flutter placeholder. The copper rim is the uncertain edge — the penumbra. Favicon and maskable PWA icons share that mark.

## Type

Inter remains the UI face (shipped by Forui, OFL). Display type is **Fraunces**, bundled at `assets/fonts/` under the OFL. Runtime Google Fonts stay rejected (ADR-005): a CDN would be a processor, a transfer, and a CSP hole.

## Motion

Quiet: fade plus a 12px rise, ~420ms, stagger 40–70ms. Routes fade. Canvas cards appear once at 0.98→1. The landing teaser drifts only when motion is allowed.

When `MediaQuery.disableAnimations` is set, motion helpers return the child unchanged (WCAG 2.2.3 / EN 301 549 7.1). They do not leave a 0ms animation chain. Route transitions collapse to 80ms.
