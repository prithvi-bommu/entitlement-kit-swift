# Architecture

EntitlementKit follows ports-and-adapters design.

```text
Host app feature gates
        │
        ▼
EntitlementKitCore ─── EntitlementKitSwiftUI (optional)
        │
        ├── EntitlementKitRevenueCat
        └── Host-owned DeviceActivationAuthorizing implementation (optional)
```

`EntitlementKitCore` has no billing SDK, network client, or UI dependency. It owns deterministic state semantics, local installation identity, web-link composition, and the device-policy boundary.

`EntitlementKitRevenueCat` is an optional adapter. It configures RevenueCat with the host app's opaque installation ID, maps `CustomerInfo` to `EntitlementStatus`, listens to `customerInfoStream`, and redeems RevenueCat Web Billing callback URLs.

The host app owns branding, browser presentation, feature gating, configuration secrets, and URL-scheme registration. It can inject `EntitlementStatusStoring`; the included UserDefaults store is an offline-availability cache, not a tamper-proof entitlement database. This keeps the same package usable across unrelated apps and billing projects.
