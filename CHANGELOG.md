# Changelog

All notable changes to `aw_router` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [0.1.1-beta] - 2025-09-01

### Added
- Zone-scoped latest-request tracking for `onError`, ensuring the freshest `AwRequest` is passed to the global exception handler across async boundaries.
- Automatic update of zone-held current request in `AwRequest.copyWith`.
- `Router.call` wrapped in `runZonedGuarded`, pushing a `CurrentRequestRef` into `zoneValues` and reading it in error handlers.
- Unit tests verifying that `onError` receives the most recent request after handler and middleware mutations.
- README note explaining Zone-scoped tracking and recommending use of `copyWith` for request modifications.
- Unified `.mount()` semantics documented: supports static and dynamic prefixes; exact match forwards `''`, remainders forward with a leading `/`.

### Changed
- Bumped package version to `0.1.1-beta`.
- Removed `smartMount`, `mossunt` and `mountWithRemainingPath` in favor of `mount`.

## [0.1.0-beta] - 2025-07-01

### Added
- Initial beta release with:
  - Declarative route registration (`GET`, `POST`, `PUT`, `PATCH`, `DELETE`, etc.).
  - Inline path parameters with regex support.
  - Composable middleware pipelines via `Pipeline` API.
  - Router mounting (`mount`), grouping (`group`), and nesting sub-handlers.
  - Customizable `onNotFound` and `onError` handlers.
  - Built-in logging middleware and `AwRequest`/`AwResponse` extensions.

### Fixed
- Corrected context-merging logic in `AwRequest.copyWith`.
- Improved default context handling for local development/testing.

[0.1.1-beta]: https://github.com/Weav3r/aw_router/compare/v0.1.0-beta...v0.1.1-beta
[0.1.0-beta]: https://github.com/Weav3r/aw_router/releases/tag/v0.1.0-beta
