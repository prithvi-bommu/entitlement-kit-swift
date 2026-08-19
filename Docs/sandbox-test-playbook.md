# RevenueCat sandbox test playbook

Run this manual checklist against a non-production RevenueCat Web Billing configuration before a host-app release. It complements deterministic package tests; it must not run in normal pull-request CI because it depends on dashboard configuration, browser checkout, and delivery of Redemption Links.

## Prerequisites

- A sandbox Web Purchase Link with anonymous checkout enabled.
- A dashboard-generated callback scheme registered by the host app.
- A test payment method and an email inbox available to the tester.
- At least two test devices when testing cross-device redemption.

## Checklist

1. Launch a fresh host-app installation and confirm it begins without paid access.
2. Select every supported plan. Confirm each checkout URL selects the expected RevenueCat package and does not contain `app_user_id`.
3. Complete sandbox checkout. Confirm that opening checkout alone does not unlock host features.
4. Receive and open the Redemption Link on the device with the host app. Confirm the callback opens the app and the expected entitlement becomes active.
5. Close and relaunch the app offline. Confirm the cached entitlement follows the documented expiry rules.
6. Redeem through a second device using the delivery flow supported by RevenueCat. Confirm both devices receive access; EntitlementKit imposes no device limit.
7. Try an expired, invalid, and already-associated Redemption Link. Confirm the host does not unlock features and gives the customer a safe retry or support path.
8. For every subscription plan, exercise renewal, cancellation, billing issue/grace, and expiry where the sandbox supports them. Confirm the host gate tracks the resulting provider entitlement.
9. Re-check the app with network access and confirm provider customer information supersedes stale local cache state.

## Recording results

Record the host-app version, environment, selected plan/package, test date, and pass/fail outcome. Do not record Redemption Link URLs, payment information, email addresses, public keys, or other customer identifiers in source control or CI logs.

## Future automation

A manually dispatched workflow with protected repository secrets may automate a narrow smoke test later. Do not add live billing credentials or external checkout to ordinary pull-request CI.
