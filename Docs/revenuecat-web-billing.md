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

The library does not claim success when checkout opens. Browser checkout is asynchronous; only redeemed/provider-confirmed customer info should unlock host-app features.

## Expired links and second devices

Redemption links are one-time and time-limited. On an expired redemption result, the host app should tell the customer to check the billing email for the replacement link. Do not collect email addresses or emulate a password-login system in the client.

## URL schemes

Use the scheme generated in the RevenueCat dashboard for the specific web configuration. Do not hard-code a shared library scheme. Every consuming application must register its own scheme in its app target configuration.
