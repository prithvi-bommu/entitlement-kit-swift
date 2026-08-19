# Implementing a provider adapter

`EntitlementKitCore` intentionally has no billing SDK or UI dependency. A billing provider belongs in its own package target, following the pattern of `EntitlementKitRevenueCat`.

## Adapter responsibilities

- Configure the provider with the host-selected identity.
- Fetch and observe provider entitlement state.
- Map provider state deterministically to `EntitlementStatus`.
- Persist provider-confirmed status through an optional `EntitlementStatusStoring` implementation.
- Handle provider-specific redemption or callback mechanisms without exposing secrets or customer identifiers.

## Host responsibilities

- Choose plan IDs, product IDs, entitlement IDs, callback schemes, and public SDK keys.
- Provide a suitable `InstallationIdentifying` implementation.
- Open checkout, register app URL handling, and present any product-specific UI.
- Apply feature gates and any account or access-control policy.

## Boundaries

Do not make the core target depend on a provider SDK, and do not introduce a generic provider abstraction merely for hypothetical adapters. Extract shared API only after a second real adapter demonstrates the common contract.
