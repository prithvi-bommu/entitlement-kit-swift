# Contributing

Keep `EntitlementKitCore` independent of vendors and UI frameworks. Provider-specific code belongs in an adapter target; app-specific plan IDs, callback schemes, and policies belong in the consuming app.

Before proposing a feature, check the [scope boundaries](README.md#scope-boundaries). In particular, account systems, backend enforcement, branded paywalls, device limits, and project-specific billing policies do not belong in this package.

Every state transition, URL-building behavior, and cache-expiry behavior needs deterministic Swift Testing coverage using fixed dates. Keep the package focused on unlimited-device entitlement redemption; host apps own any separate access-control rules.

## Change workflow

`main` is the release line. Do not commit directly to it after repository setup.

1. Start from current `main` and create a focused topic branch (`feature/...`, `fix/...`, or `docs/...`).
2. Add or update tests and documentation with the change.
3. Run the validation commands below.
4. Push the branch and open a pull request against `main`.
5. Merge only after the required CI checks pass and the pull request has been reviewed.

Use a release tag only for a tested commit already on `main`. Keep public API additions backward-compatible within a minor release and record user-visible changes in `CHANGELOG.md`. Document breaking changes prominently before a major release; while the package is pre-1.0, use a minor version for a breaking public API change.

Run before opening a pull request:

```bash
swift package resolve
swift test
```
