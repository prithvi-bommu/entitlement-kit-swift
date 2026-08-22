# Changelog

All notable user-facing changes are documented here. Releases are tagged only from tested commits on `main`.

## Unreleased

## v0.3.0

### Added

- `ActivationCode`, which renders an installation's App User ID as a short checksummed code and parses it back, so a customer can unlock a second device without an emailed redemption link.
- `KeychainInstallationIdentity`, an installation identity stored in the device-only login keychain. It survives deleting and reinstalling the host app, and can adopt an existing `UserDefaults` value so hosts switching over do not reissue identities to their current installs.
- `InstallationIdentityUpdating`, an opt-in protocol that lets an identity persist an adopted App User ID. `UserDefaultsInstallationIdentity` and `KeychainInstallationIdentity` both conform.
- `RevenueCatEntitlementGateway.activationCode()` and `activate(withCode:)`, returning `ActivationResult` / `ActivationFailure`.

### Documentation

- Documented callback routing for menu-bar and `LSUIElement` apps, status observation bridges for SwiftUI hosts, and dedicated status-cache storage keys.

## v0.2.0

### Changed

- Clarified that EntitlementKit supports unlimited-device redemption only. Device-policy public APIs were removed after `v0.1.0`; host products must implement any separate access-control policy themselves.
- Clarified lifetime-product mapping, installation-identity persistence, and package scope boundaries.
- `RevenueCatEntitlementGateway.redeem(url:)` now returns `RedemptionResult` instead of `Bool`, a source-breaking pre-1.0 API change that distinguishes unrelated links, successful redemptions, and safe failure categories.

### Added

- `RedemptionResult`, `RedemptionFailure`, configuration validation, callback URL routing, and result-based Web Purchase Link construction APIs.

## v0.1.0

Initial reusable package release.
