# RevenueCat Web Billing

## Required dashboard setup

1. Create RevenueCat Web Billing products and attach them to the entitlement for the host app.
2. Create an offering and Web Purchase Link.
3. Enable Redemption Links, first in sandbox only.
4. Copy the dashboard-generated redemption callback scheme into the host app's URL Types configuration.
5. Configure the production link only after the callback flow is verified.

## Purchase flow

1. The host app uses `WebPurchaseLinkBuilder` with its selected plan.
2. The app opens the anonymous Web Purchase Link in the default browser.
3. RevenueCat hosts checkout and sends/shows a one-time redemption link.
4. The user opens that link on the device containing the host app.
5. The app forwards the callback URL to `RevenueCatEntitlementGateway.redeem(url:)`.
6. RevenueCat associates the purchase and `customerInfoStream` supplies the resulting entitlement state.

The library does not claim success when checkout opens. Browser checkout is asynchronous; only redeemed/provider-confirmed customer info should unlock host-app features. `redeem(url:)` returns a `RedemptionResult`: `.notRedemptionURL`, `.redeemed(status)`, or `.failed(reason)`. Hosts should only take a success path for `.redeemed` and should show an appropriate retry or support path for a failure.

## Expired links and second devices

Redemption links are one-time and time-limited. On an expired redemption result, the host app should tell the customer to check the billing email for the replacement link. Do not collect email addresses or emulate a password-login system in the client.

## URL schemes

Use the scheme generated in the RevenueCat dashboard for the specific web configuration. Do not hard-code a shared library scheme. Every consuming application must register its own scheme in its app target configuration.

`WebBillingConfiguration.handlesCallbackURL(_:)` lets the host route only its own callback URLs to the gateway. This is an integration guard; RevenueCat still validates whether a routed link is a redeemable Redemption Link.

## Local configuration checks

Before opening checkout, use `WebPurchaseLinkBuilder.buildURL(configuration:planID:)` when the host needs an actionable error. It rejects a non-HTTPS checkout URL, an anonymous link containing `app_user_id`, an invalid callback scheme, blank plan/package IDs, and an unavailable package mapping. These checks cannot confirm dashboard configuration or an active purchase link, so every release still needs a sandbox test.
