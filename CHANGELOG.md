# Changelog

All notable user-facing changes are documented here. Releases are tagged only from tested commits on `main`.

## Unreleased

### Changed

- Clarified that EntitlementKit supports unlimited-device redemption only. Device-policy public APIs were removed after `v0.1.0`; host products must implement any separate access-control policy themselves.
- Clarified lifetime-product mapping, installation-identity persistence, and package scope boundaries.
- `RevenueCatEntitlementGateway.redeem(url:)` now returns `RedemptionResult` instead of `Bool`, a source-breaking pre-1.0 API change that distinguishes unrelated links, successful redemptions, and safe failure categories.

### Added

- `RedemptionResult`, `RedemptionFailure`, configuration validation, callback URL routing, and result-based Web Purchase Link construction APIs.

## v0.1.0

Initial reusable package release.
