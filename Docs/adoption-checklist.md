# Adoption checklist

## Provider configuration

- [ ] Create products in the billing provider, then import them into RevenueCat.
- [ ] Define the entitlement, offering, Web Purchase Link, Redemption Links, and dashboard callback scheme.
- [ ] Use RevenueCat package object IDs for `packageIDsByPlanID`, not lookup keys.
- [ ] Use the matching public SDK key; never commit a RevenueCat REST secret.

## Host application

- [ ] Register the callback scheme in `CFBundleURLTypes` exactly as configured.
- [ ] Route URLs with `.onOpenURL` for windowed apps or `NSApplicationDelegate.application(_:open:)` for menu-bar / `LSUIElement` apps.
- [ ] Choose an identity; use `KeychainInstallationIdentity` with its prior UserDefaults key to migrate existing installs.
- [ ] Give the status cache a fresh storage key that has not held another type.
- [ ] Decide whether to expose activation codes for second devices.
- [ ] Bridge `gateway.$status` into the host observation system when using `@Observable`.

## Verification

- [ ] Verify checkout, redemption callback cold start, renewal, cancellation, grace, expiry, and offline cache behavior in sandbox.
- [ ] Verify cross-device activation if it is offered.
- [ ] Confirm sandbox keys and links cannot reach a release build.
