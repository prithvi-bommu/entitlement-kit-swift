# Contributing

Keep `EntitlementKitCore` independent of vendors and UI frameworks. Provider-specific code belongs in an adapter target; app-specific plan IDs, callback schemes, and policies belong in the consuming app.

Every state transition, URL-building behavior, and cache-expiry behavior needs deterministic Swift Testing coverage using fixed dates. Keep the package focused on unlimited-device entitlement redemption; host apps own any separate access-control rules.

Run before opening a pull request:

```bash
swift package resolve
swift test
```
