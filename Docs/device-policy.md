# Device policy

## Unlimited devices

Use `DevicePolicy.unlimited` for products that allow the billing email holder to redeem on any number of devices. RevenueCat Redemption Links support this by issuing a one-time link for each new device.

## Capped devices

`DevicePolicy.serverEnforced(maximumDevices:)` declares the policy but does not enforce it locally. A local check is not secure: a user can alter application storage, clone an install, or modify a client binary.

Implement `DeviceActivationAuthorizing` in a host-specific server client. The server should:

1. Authenticate and validate the active RevenueCat entitlement server-side.
2. Register a privacy-preserving installation identifier or public-key fingerprint.
3. Count active installations per RevenueCat customer/purchase according to the product policy.
4. Return an allow/deny decision and issue a short-lived signed activation lease.
5. Support deactivation, device replacement, and support override workflows.

The server is intentionally not included in this repository. It has deployment, authentication, retention, and legal requirements that differ per product. The stable protocol makes each project easy to connect without pretending caps can be enforced by a package alone.
