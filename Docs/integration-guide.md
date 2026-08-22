# Host integration guide

This guide describes the smallest supported host-app integration for anonymous RevenueCat Web Billing. Keep every product-specific value in the host app: public SDK key, entitlement ID, Web Purchase Link, package IDs, and callback scheme.

## 1. Construct stable local dependencies

Use a stable installation identity and a status cache whose keys are unique to the host app. `UserDefaultsInstallationIdentity` is installation-scoped, so replace it with a host-owned Keychain implementation only when persistence across deletion and reinstall is a product requirement.

```swift
let identity = UserDefaultsInstallationIdentity(key: "com.example.app.installation-id")
let statusStore = UserDefaultsEntitlementStatusStore(
    key: "com.example.app.cached-entitlement"
)

let gateway = RevenueCatEntitlementGateway(
    apiKey: "appl_public_sdk_key",
    entitlementID: "example_pro",
    lifetimePlanIDs: ["com.example.app.lifetime"],
    identity: identity,
    statusStore: statusStore
)

await gateway.configure()
```

The cache gives the host an offline status, but RevenueCat remains the source of truth whenever it can be reached.

## 2. Build an anonymous checkout URL

Create an anonymous RevenueCat Web Purchase Link in the dashboard, then map host plan IDs to RevenueCat package IDs. Do not include the local installation ID or an `app_user_id` in this URL.

```swift
let billing = WebBillingConfiguration(
    purchaseLink: URL(string: "https://pay.rev.cat/example")!,
    packageIDsByPlanID: [
        "monthly": "$rc_monthly",
        "annual": "$rc_annual"
    ],
    callbackScheme: "dashboard-generated-scheme"
)

let checkoutURL: URL
switch WebPurchaseLinkBuilder.buildURL(
    configuration: billing,
    planID: "annual"
) {
case .success(let url):
    checkoutURL = url
case .failure(let error):
    // Present a safe host-owned fallback. `error` distinguishes an invalid
    // configuration from a missing plan-to-package mapping.
    return
}
```

Open `checkoutURL` with the platform browser API. Opening checkout is not a purchase success event.

## 3. Register and route the callback

Register the dashboard-generated callback scheme in the app target. For a window-based SwiftUI app, forward incoming URLs using `.onOpenURL`:

```swift
.onOpenURL { url in
    guard billing.handlesCallbackURL(url) else {
        return
    }
    Task {
        switch await gateway.redeem(url: url) {
        case .notRedemptionURL:
            break
        case .redeemed(let status) where status.hasAccess:
            // Unlock host-owned features.
            break
        case .redeemed:
            // The link redeemed, but not for an entitlement this host grants.
            break
        case .failed:
            // Present a safe retry or support path.
            break
        }
    }
}
```

For a menu-bar or `LSUIElement` app, use `NSApplicationDelegate.application(_:open:)` instead: `.onOpenURL` is unreliable when no window receives the URL.

```swift
final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        Task { @MainActor in
            for url in urls where billing.handlesCallbackURL(url) {
                _ = await gateway.redeem(url: url)
            }
        }
    }
}
```

The user may open the Redemption Link on a different device. RevenueCat's redemption flow associates it with the local app user identity; EntitlementKit deliberately has no device cap.

## 4. Offer an activation code for second devices

For a no-email cross-device flow, display `gateway.activationCode()` on the
already-entitled device and call `activate(withCode:)` on the second device.
Use `KeychainInstallationIdentity` or another `InstallationIdentityUpdating`
implementation so the adopted identity persists after relaunch.

## 5. Gate product features in the host

Observe `gateway.status` and use `status.hasAccess` as the entitlement input to host-owned feature gates. A `.redeemed` result alone is not a grant: gate on the result's `status.hasAccess` or the observed `gateway.status`. Do not put branded paywall UI, account logic, or authorization policy in the shared package.

## 6. Validate before release

Run the deterministic Swift tests in every pull request, then run the [manual sandbox test playbook](sandbox-test-playbook.md) with the host app's non-production RevenueCat configuration before release.
