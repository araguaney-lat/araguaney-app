# Contributing to Araguaney App

Thank you for your interest in contributing. This document describes the conventions and the workflow this repository follows. They mirror the conventions of the [backend repository](https://github.com/araguaney-lat/araguaney) so that the two projects feel like one system.

## Ground rules

1. **This is a thin client.** Business rules (validation, state machines, tenant scoping, risk controls) live in the backend and are enforced there. If a feature seems to require business logic in the client, the correct first step is usually a backend endpoint, not client-side logic. Pull requests that duplicate backend rules in the client will be asked to restructure.

2. **The API contract is additive-only.** The application consumes the backend's `/v1` API through a Dart client generated from the vendored OpenAPI snapshot (`api/openapi.json`). Do not hand-edit generated code. To pick up new backend capabilities, update the snapshot in its own commit and regenerate.

3. **Deliberate boundaries are not bugs.** Some behaviors that may look like missing features are documented domain rules — most notably, offline writing is limited to donation intake capture. Read `docs/design/` before proposing changes to these areas.

## Language conventions

- **All identifiers are written in English**: functions, variables, classes, files, routes.
- **Product prose is written in Spanish**: user-facing strings, error messages shown to operators, and domain documentation. The platform operates in Spanish-speaking collection centers.
- **Contributor-facing prose is written in English**: commit messages, pull request text, and repository documentation (this file, the README, security policy).

## Workflow

1. Create a branch from `main` (`feat/…`, `fix/…`, `refactor/…`, `docs/…`, `chore/…`). Direct pushes to `main` are not accepted.
2. Commit using [Conventional Commits](https://www.conventionalcommits.org/) (`type: description`).
3. Ensure quality gates pass locally before opening a pull request:
   - `flutter analyze` with no issues,
   - `dart format` applied,
   - `flutter test` passing.
4. Open a pull request describing what problem it solves, how, what does not change, and how it was verified.

## Testing expectations

- New behavior comes with tests (unit or widget as appropriate).
- Code that touches the local database or the offline queue is tested against a real in-memory SQLite database, not mocks: most defects in that layer live in transaction handling, and mocks do not reproduce them.
- Test names are written in English.

## Security

Do not open public issues for security vulnerabilities. See [SECURITY.md](SECURITY.md).

## License of contributions

By contributing, you agree that your contributions are licensed under the GNU General Public License v3.0 or later, including the additional permission for application store distribution described in [LICENSE-EXCEPTIONS.md](LICENSE-EXCEPTIONS.md).
