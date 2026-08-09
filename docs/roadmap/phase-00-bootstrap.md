# Phase 00 — Repository bootstrap and application scaffold

> Everything needed before the first feature: a public repository with formal
> documentation, a licensing decision compatible with application stores, an
> approved architecture design, and a Flutter scaffold that compiles, passes
> strict analysis, and runs its tests in CI.
>
> **Design:** `docs/design/2026-08-09-app-architecture.md`

---

## Objectives

1. A public repository an external evaluator can read and trust.
2. An architecture recorded as a decision document, not tribal knowledge.
3. A compiling scaffold with quality gates enforced from the first pull request.

## Non-objectives

- Any backend interaction (API client, authentication): Phase 01+.
- Store distribution: Phase 08 (Android) and Phase 09 (iOS).

---

## Tasks

| # | Task | Description | Complexity | Status |
|---|------|-------------|------------|--------|
| 1 | Public repository | `araguaney-lat/araguaney-app`, protected `main` (PR required, no force push), private vulnerability reporting enabled. | 🟢 Low | ✅ Done |
| 2 | License | GPL-3.0-or-later plus additional permission under GPLv3 §7 for application store distribution (`LICENSE-EXCEPTIONS.md`). | 🟠 Medium | ✅ Done |
| 3 | Repository documentation | README, CONTRIBUTING (workflow, language conventions, bilingual PRs), SECURITY, CLAUDE.md. All docs in English by policy. | 🟠 Medium | ✅ Done |
| 4 | Architecture design document | Framework choice with evaluated alternatives, thin-client premise, offline boundary, push isolation, licensing rationale, risks. | 🟠 Medium | ✅ Done |
| 5 | Flutter scaffold | `flutter create` (org `lat.araguaney`, Android/iOS), README and root docs preserved. | 🟢 Low | ✅ Done |
| 6 | Feature-first structure | `lib/core/` (api, auth, db, push, config, i18n, routing, widgets) and `lib/features/` (session, intake, scan, boxes, pallets, shipments, dashboard). | 🟠 Medium | ✅ Done |
| 7 | Localization baseline | `gen-l10n` with Spanish as default and template locale (`app_es.arb`). | 🟢 Low | ✅ Done |
| 8 | Strict analysis and formatting | `flutter_lints` + `strict-casts`/`strict-inference`/`strict-raw-types` + additional rules; `dart format` enforced. | 🟢 Low | ✅ Done |
| 9 | CI | GitHub Actions: format check, analyzer, tests on every PR and push to `main`. | 🟠 Medium | ✅ Done |
| 10 | Android build verified | Local toolchain without heavy IDEs (cmdline-tools + JDK 17); `compileSdk` 37 fix; `flutter build apk --debug` succeeds. | 🟠 Medium | ✅ Done |

---

## Suggested order

Completed. Delivered through PRs #1, #2, and #3.
